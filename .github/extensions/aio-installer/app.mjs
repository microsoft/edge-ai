/* global document, window */

const BLUEPRINT_STAGES = [
  ["selected", "Select"],
  ["authenticated", "Azure"],
  ["parameters-prepared", "Parameters"],
  ["validated", "Validate"],
  ["planned", "Plan"],
  ["applied", "Apply"],
  ["verified", "Verify"],
];
const GENERIC_STAGES = [
  ["selected", "Select"],
  ["authenticated", "Azure"],
  ["prerequisites", "Prerequisites"],
  ["dependencies", "Dependencies"],
  ["initialized", "Initialize"],
  ["created", "Create"],
  ["verified", "Verify"],
];

const elements = {
  pipeline: document.querySelector("#pipeline"),
  badge: document.querySelector("#state-badge"),
  facts: document.querySelector("#facts"),
  error: document.querySelector("#deployment-error"),
  timestamp: document.querySelector("#timestamp"),
  refresh: document.querySelector("#refresh"),
  form: document.querySelector("#configuration"),
  blueprint: document.querySelector("#blueprint"),
  tenant: document.querySelector("#tenant"),
  subscription: document.querySelector("#subscription"),
  environment: document.querySelector("#environment"),
  resourcePrefix: document.querySelector("#resource-prefix"),
  location: document.querySelector("#location"),
  instance: document.querySelector("#instance"),
  overlays: document.querySelector("#overlays"),
  overlaysFieldset: document.querySelector("#overlays-fieldset"),
  approvalRow: document.querySelector("#approval-row"),
  applyApproved: document.querySelector("#apply-approved"),
  formStatus: document.querySelector("#form-status"),
  progress: document.querySelector("#progress-log"),
  progressStatus: document.querySelector("#progress-status"),
};

let currentSnapshot = null;
let formDirty = false;

function text(value, fallback = "Not set") {
  return typeof value === "string" && value ? value : fallback;
}

function activeFramework() {
  return elements.form.querySelector('input[name="framework"]:checked')?.value || "terraform";
}

function stagesForState(state) {
  return state.deploymentPath === "generic-cli"
    ? GENERIC_STAGES
    : BLUEPRINT_STAGES;
}

function renderPipeline(state) {
  const stages = stagesForState(state);
  const completed = stages.findIndex(([id]) => id === state.lastSuccessfulStage);
  const current = stages.findIndex(([id]) => id === state.status);
  const active = current > completed ? current : completed + 1;
  const failed = state.status === "failed" ? completed + 1 : -1;
  const fragment = document.createDocumentFragment();
  stages.forEach(([, label], index) => {
    const item = document.createElement("li");
    item.className = index <= completed ? "done" : index === failed ? "failed" : "pending";
    if (index === active && failed < 0) {
      item.className = "active";
    }
    const marker = document.createElement("span");
    marker.textContent = index <= completed ? "✓" : String(index + 1);
    const name = document.createElement("strong");
    name.textContent = label;
    item.append(marker, name);
    fragment.append(item);
  });
  elements.pipeline.replaceChildren(fragment);
}

function addFact(fragment, term, value) {
  const dt = document.createElement("dt");
  const dd = document.createElement("dd");
  dt.textContent = term;
  dd.textContent = text(value);
  fragment.append(dt, dd);
}

function renderSummary(snapshot) {
  const { state } = snapshot;
  elements.badge.textContent = state.status.replaceAll("-", " ");
  elements.badge.dataset.status = state.status;
  renderPipeline(state);
  const facts = document.createDocumentFragment();
  addFact(
    facts,
    "Path",
    state.deploymentPath === "generic-cli"
      ? "Generic local Azure CLI"
      : state.deploymentPath === "edge-ai-blueprint"
        ? "Edge AI blueprint"
        : null,
  );
  addFact(
    facts,
    "Runtime",
    state.runtime === "preview"
      ? "Preview (--use-preview)"
      : state.runtime === "stable"
        ? "Stable (GA)"
        : null,
  );
  addFact(facts, "Blueprint", state.blueprint);
  addFact(facts, "Framework", state.framework);
  addFact(facts, "Subscription", state.azure.subscriptionName || state.azure.subscriptionId);
  addFact(facts, "Parameters", state.parameterFile);
  addFact(facts, "Overlays", state.overlays.length ? state.overlays.join(", ") : "None");
  addFact(facts, "Deployment", state.deploymentName);
  elements.facts.replaceChildren(facts);
  elements.error.hidden = !state.error;
  elements.error.textContent = state.error || "";
  elements.timestamp.textContent = state.updatedAt ? `Updated ${new Date(state.updatedAt).toLocaleString()}` : "Waiting for installer state";
  elements.approvalRow.hidden = state.lastSuccessfulStage !== "planned";
  elements.form.hidden = state.deploymentPath === "generic-cli";
}

function renderProgress(progress = []) {
  const wasNearBottom = elements.progress.scrollHeight
    - elements.progress.scrollTop
    - elements.progress.clientHeight < 48;
  const fragment = document.createDocumentFragment();
  progress.forEach((event) => {
    const item = document.createElement("li");
    item.dataset.status = event.status;
    const header = document.createElement("div");
    const label = document.createElement("strong");
    const timestamp = document.createElement("time");
    label.textContent = event.label;
    timestamp.dateTime = event.timestamp;
    timestamp.textContent = new Date(event.timestamp).toLocaleTimeString();
    header.append(label, timestamp);
    item.append(header);
    if (event.message) {
      const message = document.createElement("pre");
      message.textContent = event.message;
      item.append(message);
    }
    fragment.append(item);
  });
  elements.progress.replaceChildren(fragment);
  const latest = progress.at(-1);
  elements.progressStatus.textContent = latest
    ? `${latest.label}: ${latest.status}`
    : "Waiting for command progress.";
  if (wasNearBottom || progress.length <= 1) {
    elements.progress.scrollTop = elements.progress.scrollHeight;
  }
}

function selectedBlueprint() {
  return currentSnapshot?.inventory.find((item) => item.name === elements.blueprint.value);
}

function renderOverlays(selected = []) {
  const blueprint = selectedBlueprint();
  const framework = activeFramework();
  elements.overlaysFieldset.hidden = framework !== "terraform";
  const fragment = document.createDocumentFragment();
  if (!blueprint?.terraformTemplates.length) {
    const empty = document.createElement("p");
    empty.className = "empty";
    empty.textContent = "No templates available for this blueprint.";
    fragment.append(empty);
  } else {
    blueprint.terraformTemplates.forEach((template) => {
      const label = document.createElement("label");
      const input = document.createElement("input");
      input.type = "checkbox";
      input.name = "overlay";
      input.value = template;
      input.checked = selected.some((path) => path.endsWith(`/${template}`) || path === template);
      label.append(input, document.createTextNode(template));
      fragment.append(label);
    });
  }
  elements.overlays.replaceChildren(fragment);
}

function setFramework(framework) {
  const input = elements.form.querySelector(`input[name="framework"][value="${framework}"]`);
  if (input) {
    input.checked = true;
  }
}

function populateForm(snapshot) {
  if (formDirty) {
    return;
  }
  const { state, inventory, feedback } = snapshot;
  const values = feedback?.values || {};
  const blueprintValue = values.blueprint || state.blueprint || "full-multi-node-cluster";
  const options = inventory.map((item) => {
    const option = document.createElement("option");
    option.value = item.name;
    option.textContent = item.name;
    return option;
  });
  elements.blueprint.replaceChildren(...options);
  if (inventory.some((item) => item.name === blueprintValue)) {
    elements.blueprint.value = blueprintValue;
  }
  const framework = values.framework || state.framework || "terraform";
  setFramework(framework);
  elements.tenant.value = values.tenant || state.azure.tenantId || "";
  elements.subscription.value = values.subscription || state.azure.subscriptionId || "";
  elements.environment.value = values.parameters?.environment || "dev";
  elements.resourcePrefix.value = values.parameters?.resourcePrefix || "";
  elements.location.value = values.parameters?.location || state.location || "eastus2";
  elements.instance.value = values.parameters?.instance || "001";
  elements.applyApproved.checked = values.applyApproved === true;
  renderOverlays(values.overlays || state.overlays);
}

async function loadSnapshot(announce = false) {
  try {
    const response = await fetch("/api/state", { headers: { Accept: "application/json" } });
    const body = await response.json();
    if (!response.ok) {
      throw new Error(body.error || `HTTP ${response.status}`);
    }
    currentSnapshot = body;
    renderSummary(body);
    renderProgress(body.progress);
    populateForm(body);
    if (announce) {
      elements.formStatus.textContent = "State refreshed.";
    }
  } catch (error) {
    elements.formStatus.textContent = `Unable to refresh: ${error.message}`;
  }
}

function feedbackPayload() {
  return {
    blueprint: elements.blueprint.value,
    framework: activeFramework(),
    tenant: elements.tenant.value.trim(),
    subscription: elements.subscription.value.trim(),
    parameters: {
      environment: elements.environment.value.trim(),
      resourcePrefix: elements.resourcePrefix.value.trim(),
      location: elements.location.value.trim(),
      instance: elements.instance.value.trim(),
    },
    overlays: [...elements.form.querySelectorAll('input[name="overlay"]:checked')]
      .map((input) => input.value),
    applyApproved: elements.applyApproved.checked,
  };
}

elements.form.addEventListener("input", () => { formDirty = true; });
elements.blueprint.addEventListener("change", () => renderOverlays());
elements.form.querySelectorAll('input[name="framework"]').forEach((input) => {
  input.addEventListener("change", () => renderOverlays());
});
elements.refresh.addEventListener("click", () => loadSnapshot(true));
elements.form.addEventListener("submit", async (event) => {
  event.preventDefault();
  elements.formStatus.textContent = "Sending choices...";
  try {
    const response = await fetch("/api/feedback", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(feedbackPayload()),
    });
    const body = await response.json();
    if (!response.ok) {
      throw new Error(body.error || `HTTP ${response.status}`);
    }
    formDirty = false;
    elements.formStatus.textContent = `Sent to agent as revision ${body.revision}.`;
    await loadSnapshot();
  } catch (error) {
    elements.formStatus.textContent = `Unable to send: ${error.message}`;
  }
});

await loadSnapshot();
const refreshTimer = window.setInterval(() => loadSnapshot(), 2000);
window.addEventListener("pagehide", () => window.clearInterval(refreshTimer), { once: true });