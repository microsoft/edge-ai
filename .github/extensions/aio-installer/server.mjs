import { createHash, randomUUID } from "node:crypto";
import { createServer } from "node:http";
import {
  chmod,
  mkdir,
  open,
  readFile,
  readdir,
  realpath,
  rename,
  rm,
  writeFile,
} from "node:fs/promises";
import { dirname, isAbsolute, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { CanvasError } from "@microsoft/copilot-sdk/extension";

const ROOT = dirname(fileURLToPath(import.meta.url));
const ASSETS = new Map([
  ["/", ["index.html", "text/html; charset=utf-8"]],
  ["/app.mjs", ["app.mjs", "text/javascript; charset=utf-8"]],
  ["/style.css", ["style.css", "text/css; charset=utf-8"]],
]);
const ALLOWED_FRAMEWORKS = new Set(["terraform", "bicep"]);
const ALLOWED_PROGRESS_STATUSES = new Set([
  "running",
  "output",
  "succeeded",
  "failed",
]);
const MAX_PROGRESS_BYTES = 256 * 1024;
const MAX_PROGRESS_EVENTS = 200;
const PARAMETER_PATTERNS = {
  environment: /^[a-z][a-z0-9-]{0,15}$/,
  resourcePrefix: /^[A-Za-z0-9]{1,8}$/,
  location: /^[a-z0-9-]{2,32}$/,
  instance: /^[A-Za-z0-9-]{1,12}$/,
};

function canvasError(code, message) {
  return new CanvasError(code, message);
}

function normalizedRelative(workspacePath, candidate) {
  if (typeof candidate !== "string" || !candidate.trim() || isAbsolute(candidate)) {
    throw canvasError("invalid_state", "input.state must be a workspace-relative JSON path.");
  }
  const normalized = relative(workspacePath, resolve(workspacePath, candidate))
    .split(sep)
    .join("/");
  if (normalized.startsWith("../")
    || !normalized.startsWith(".copilot-tracking/aio-installer/")
    || !normalized.endsWith(".json")) {
    throw canvasError(
      "invalid_state",
      "input.state must stay under .copilot-tracking/aio-installer/ and end in .json.",
    );
  }
  return normalized;
}

async function readJson(filePath, missingValue) {
  try {
    return JSON.parse(await readFile(filePath, "utf8"));
  } catch (error) {
    if (error.code === "ENOENT") {
      return missingValue;
    }
    if (error instanceof SyntaxError) {
      throw canvasError("invalid_json", `Invalid JSON at ${filePath}.`);
    }
    throw error;
  }
}

async function writeJsonAtomically(filePath, value) {
  await mkdir(dirname(filePath), { recursive: true });
  const temporary = `${filePath}.${randomUUID()}.tmp`;
  try {
    await writeFile(temporary, `${JSON.stringify(value, null, 2)}\n`, { flag: "wx", mode: 0o600 });
    await chmod(temporary, 0o600);
    await rename(temporary, filePath);
  } finally {
    await rm(temporary, { force: true });
  }
}

function sanitizeInstallerState(value) {
  if (value === null) {
    return {
      deploymentPath: null,
      runtime: null,
      status: "not-started",
      lastSuccessfulStage: null,
      blueprint: null,
      framework: null,
      azure: { tenantId: null, subscriptionId: null, subscriptionName: null },
      parameterFile: null,
      overlays: [],
      deploymentName: null,
      location: null,
      error: null,
      updatedAt: null,
    };
  }
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw canvasError("invalid_state", "Installer state must be a JSON object.");
  }
  if (value.schema_version !== 1) {
    throw canvasError("invalid_state", "Installer state schema_version must be 1.");
  }
  return {
    deploymentPath: value.deployment_path === "generic-cli"
      ? "generic-cli"
      : value.deployment_path === "edge-ai-blueprint" || typeof value.blueprint === "string"
        ? "edge-ai-blueprint"
        : null,
    runtime: value.runtime === "stable" || value.runtime === "preview"
      ? value.runtime
      : null,
    status: typeof value.status === "string" ? value.status : "unknown",
    lastSuccessfulStage: typeof value.last_successful_stage === "string"
      ? value.last_successful_stage
      : null,
    blueprint: typeof value.blueprint === "string" ? value.blueprint : null,
    framework: ALLOWED_FRAMEWORKS.has(value.framework) ? value.framework : null,
    azure: {
      tenantId: typeof value.azure?.tenant_id === "string" ? value.azure.tenant_id : null,
      subscriptionId: typeof value.azure?.subscription_id === "string"
        ? value.azure.subscription_id
        : null,
      subscriptionName: typeof value.azure?.subscription_name === "string"
        ? value.azure.subscription_name
        : null,
    },
    parameterFile: typeof value.parameter_file === "string" ? value.parameter_file : null,
    overlays: Array.isArray(value.overlays)
      ? value.overlays.filter((item) => typeof item === "string")
      : [],
    deploymentName: typeof value.deployment_name === "string" ? value.deployment_name : null,
    location: typeof value.location === "string" ? value.location : null,
    error: typeof value.error === "string" ? value.error : null,
    updatedAt: typeof value.updated_at === "string" ? value.updated_at : null,
  };
}

function stripAnsi(value) {
  let result = "";
  let index = 0;
  while (index < value.length) {
    if (value.charCodeAt(index) === 27 && value[index + 1] === "[") {
      index += 2;
      while (index < value.length) {
        const code = value.charCodeAt(index);
        index += 1;
        if (code >= 64 && code <= 126) {
          break;
        }
      }
    } else {
      result += value[index];
      index += 1;
    }
  }
  return result;
}

function redactProgressText(value, maximum) {
  return stripAnsi(value)
    .replace(
      /(authorization|password|passwd|secret|token|api[_ -]?key|connection[_ -]?string)(?:"?\s*[=:]\s*|\s+)("[^"]*"|'[^']*'|[^,;\s]+)/gi,
      "[REDACTED_SECRET]",
    )
    .replace(/bearer\s+\S+/gi, "Bearer [REDACTED]")
    .replace(
      /[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}/g,
      "[REDACTED_JWT]",
    )
    .replace(/[A-Za-z0-9+/]{40,}={0,2}/g, "[REDACTED]")
    .replace(
      /[\w.%+-]+@[\w.-]+\.[A-Za-z]{2,}/g,
      "[REDACTED_EMAIL]",
    )
    .slice(0, maximum);
}

function validateProgressEvent(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)
    || value.version !== 1
    || typeof value.timestamp !== "string"
    || typeof value.stage !== "string"
    || !/^[a-z][a-z0-9-]{0,31}$/.test(value.stage)
    || !ALLOWED_PROGRESS_STATUSES.has(value.status)
    || typeof value.label !== "string"
    || value.label.length < 1
    || value.label.length > 120
    || !(value.message === null || typeof value.message === "string")
    || !(value.exitCode === null || Number.isInteger(value.exitCode))) {
    return null;
  }
  return {
    timestamp: value.timestamp,
    stage: value.stage,
    status: value.status,
    label: redactProgressText(value.label, 120),
    message: value.message === null
      ? null
      : redactProgressText(value.message, 1000),
    exitCode: value.exitCode,
  };
}

async function readProgress(filePath) {
  let handle;
  try {
    handle = await open(filePath, "r");
    const { size } = await handle.stat();
    const length = Math.min(size, MAX_PROGRESS_BYTES);
    const offset = size - length;
    const buffer = Buffer.alloc(length);
    const { bytesRead } = await handle.read(buffer, 0, length, offset);
    let content = buffer.subarray(0, bytesRead).toString("utf8");
    if (offset > 0) {
      const firstNewline = content.indexOf("\n");
      content = firstNewline < 0 ? "" : content.slice(firstNewline + 1);
    }
    if (content && !content.endsWith("\n")) {
      content = content.slice(0, content.lastIndexOf("\n") + 1);
    }
    return content
      .split("\n")
      .filter(Boolean)
      .map((line) => {
        try {
          return validateProgressEvent(JSON.parse(line));
        } catch {
          return null;
        }
      })
      .filter(Boolean)
      .slice(-MAX_PROGRESS_EVENTS);
  } catch (error) {
    if (error.code === "ENOENT") {
      return [];
    }
    throw error;
  } finally {
    await handle?.close();
  }
}

function validateStoredFeedback(value) {
  if (value === null) {
    return null;
  }
  if (!value || typeof value !== "object" || Array.isArray(value)
    || value.format !== "edge-ai-aio-installer-feedback"
    || value.version !== 1
    || !Number.isInteger(value.revision)
    || value.revision < 1
    || typeof value.submittedAt !== "string"
    || !(value.acknowledgedAt === null || typeof value.acknowledgedAt === "string")
    || !value.values
    || typeof value.values !== "object"
    || Array.isArray(value.values)) {
    throw canvasError("invalid_feedback", "Stored canvas feedback has an unsupported format.");
  }
  return value;
}

async function discoverInventory(workspacePath) {
  const blueprintsPath = join(workspacePath, "blueprints");
  let entries;
  try {
    entries = await readdir(blueprintsPath, { withFileTypes: true });
  } catch (error) {
    if (error.code === "ENOENT") {
      return [];
    }
    throw error;
  }
  const inventory = [];
  for (const entry of entries.filter((item) => item.isDirectory())) {
    const frameworks = [];
    const terraformTemplates = [];
    for (const framework of ALLOWED_FRAMEWORKS) {
      try {
        const frameworkEntries = await readdir(join(blueprintsPath, entry.name, framework));
        frameworks.push(framework);
        if (framework === "terraform") {
          terraformTemplates.push(...frameworkEntries
            .filter((name) => name.endsWith(".tfvars.example"))
            .sort());
        }
      } catch (error) {
        if (error.code !== "ENOENT") {
          throw error;
        }
      }
    }
    if (frameworks.length > 0) {
      inventory.push({ name: entry.name, frameworks, terraformTemplates });
    }
  }
  return inventory.sort((left, right) => left.name.localeCompare(right.name));
}

function optionalString(value, name, maximum, pattern) {
  if (value === undefined || value === null || value === "") {
    return null;
  }
  if (typeof value !== "string" || value.length > maximum || (pattern && !pattern.test(value))) {
    throw canvasError("invalid_feedback", `${name} is invalid.`);
  }
  return value;
}

function validateFeedback(input, inventory) {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    throw canvasError("invalid_feedback", "Feedback must be a JSON object.");
  }
  const blueprint = optionalString(input.blueprint, "blueprint", 80, /^[a-z0-9][a-z0-9-]*$/);
  const selected = inventory.find((item) => item.name === blueprint);
  if (blueprint && !selected) {
    throw canvasError("invalid_feedback", "Blueprint is not available.");
  }
  const framework = optionalString(input.framework, "framework", 16);
  if (framework && (!ALLOWED_FRAMEWORKS.has(framework) || !selected?.frameworks.includes(framework))) {
    throw canvasError("invalid_feedback", "Framework is not available for the selected blueprint.");
  }
  const overlays = Array.isArray(input.overlays) ? [...new Set(input.overlays)] : [];
  if (overlays.some((item) => typeof item !== "string"
    || !selected?.terraformTemplates.includes(item))) {
    throw canvasError("invalid_feedback", "One or more Terraform overlays are unavailable.");
  }
  const parameters = input.parameters && typeof input.parameters === "object"
    ? input.parameters
    : {};
  return {
    blueprint,
    framework,
    tenant: optionalString(input.tenant, "tenant", 128),
    subscription: optionalString(input.subscription, "subscription", 128),
    parameters: Object.fromEntries(Object.entries(PARAMETER_PATTERNS).map(([name, pattern]) => [
      name,
      optionalString(parameters[name], name, 32, pattern),
    ])),
    overlays: framework === "terraform" ? overlays : [],
    applyApproved: input.applyApproved === true,
  };
}

export async function createInstallerStore(workspacePath, stateInput) {
  const workspace = await realpath(workspacePath);
  const stateRelative = normalizedRelative(workspace, stateInput);
  const statePath = resolve(workspace, stateRelative);
  const progressPath = `${statePath}.progress.ndjson`;
  await mkdir(dirname(statePath), { recursive: true });
  const parent = await realpath(dirname(statePath));
  if (relative(workspace, parent).startsWith("..")) {
    throw canvasError("invalid_state", "Installer state parent resolves outside the workspace.");
  }
  const feedbackKey = createHash("sha256").update(stateRelative).digest("hex").slice(0, 16);
  const feedbackPath = join(parent, `canvas-feedback-${feedbackKey}.json`);

  async function snapshot() {
    const [state, inventory, feedback, progress] = await Promise.all([
      readJson(statePath, null).then(sanitizeInstallerState),
      discoverInventory(workspace),
      readJson(feedbackPath, null).then(validateStoredFeedback),
      readProgress(progressPath),
    ]);
    return {
      statePath: stateRelative,
      state,
      inventory,
      feedback: feedback && feedback.acknowledgedAt === null ? feedback : null,
      progress,
    };
  }

  return {
    identity: stateRelative,
    snapshot,
    async submitFeedback(input) {
      const inventory = await discoverInventory(workspace);
      const values = validateFeedback(input, inventory);
      const current = validateStoredFeedback(await readJson(feedbackPath, null));
      const feedback = {
        format: "edge-ai-aio-installer-feedback",
        version: 1,
        revision: current ? current.revision + 1 : 1,
        submittedAt: new Date().toISOString(),
        acknowledgedAt: null,
        values,
      };
      await writeJsonAtomically(feedbackPath, feedback);
      return feedback;
    },
    async getFeedback() {
      const feedback = validateStoredFeedback(await readJson(feedbackPath, null));
      if (!feedback || feedback.acknowledgedAt !== null) {
        return { feedback: null };
      }
      return { feedback };
    },
    async acknowledgeFeedback(revision) {
      if (!Number.isInteger(revision) || revision < 1) {
        throw canvasError("invalid_revision", "revision must be a positive integer.");
      }
      const feedback = validateStoredFeedback(await readJson(feedbackPath, null));
      if (!feedback) {
        throw canvasError("feedback_missing", "No canvas feedback exists.");
      }
      if (feedback.revision !== revision) {
        throw canvasError("feedback_changed", "Canvas feedback changed; read it again before acknowledging.");
      }
      const acknowledged = { ...feedback, acknowledgedAt: new Date().toISOString() };
      await writeJsonAtomically(feedbackPath, acknowledged);
      return { revision, acknowledgedAt: acknowledged.acknowledgedAt };
    },
  };
}

export async function startInstallerServer({ store, log }) {
  const cookie = randomUUID();

  function sendJson(response, status, value) {
    response.writeHead(status, { "Content-Type": "application/json; charset=utf-8" });
    response.end(JSON.stringify(value));
  }

  function authorized(request) {
    return String(request.headers.cookie || "")
      .split(";")
      .map((item) => item.trim())
      .includes(`aio_canvas=${cookie}`);
  }

  const server = createServer(async (request, response) => {
    response.setHeader("Cache-Control", "no-store");
    response.setHeader("X-Content-Type-Options", "nosniff");
    response.setHeader("Referrer-Policy", "no-referrer");
    response.setHeader(
      "Content-Security-Policy",
      "default-src 'self'; script-src 'self'; style-src 'self'; connect-src 'self'; img-src 'self' data:",
    );
    if (request.headers.host !== new URL(origin).host) {
      sendJson(response, 403, { error: "Host not allowed." });
      return;
    }
    const url = new URL(request.url, origin);
    try {
      if (request.method === "GET" && ASSETS.has(url.pathname)) {
        const [fileName, contentType] = ASSETS.get(url.pathname);
        if (url.pathname === "/") {
          response.setHeader("Set-Cookie", `aio_canvas=${cookie}; HttpOnly; SameSite=Strict; Path=/`);
        }
        response.writeHead(200, { "Content-Type": contentType });
        response.end(await readFile(join(ROOT, fileName)));
      } else if (request.method === "GET" && url.pathname === "/api/state") {
        if (!authorized(request)) {
          sendJson(response, 403, { error: "Canvas session is not authorized." });
          return;
        }
        sendJson(response, 200, await store.snapshot());
      } else if (request.method === "POST" && url.pathname === "/api/feedback") {
        if (!authorized(request) || request.headers.origin !== origin
          || request.headers["content-type"] !== "application/json") {
          sendJson(response, 403, { error: "Origin or content type not allowed." });
          return;
        }
        let body = "";
        for await (const chunk of request) {
          body += chunk;
          if (body.length > 16384) {
            sendJson(response, 413, { error: "Feedback is too large." });
            return;
          }
        }
        let parsed;
        try {
          parsed = JSON.parse(body);
        } catch {
          sendJson(response, 400, { error: "Feedback must be valid JSON." });
          return;
        }
        sendJson(response, 200, await store.submitFeedback(parsed));
      } else {
        sendJson(response, 404, { error: "Resource not found." });
      }
    } catch (error) {
      await log(error.stack || String(error));
      const status = error instanceof CanvasError ? 400 : 500;
      sendJson(response, status, { error: error.message || "Canvas request failed." });
    }
  });

  await new Promise((resolveListen, rejectListen) => {
    server.once("error", rejectListen);
    server.listen(0, "127.0.0.1", resolveListen);
  });
  const origin = `http://127.0.0.1:${server.address().port}`;

  return {
    url: origin,
    async close() {
      await new Promise((resolveClose, rejectClose) => {
        server.close((error) => (error ? rejectClose(error) : resolveClose()));
        server.closeAllConnections();
      });
    },
  };
}