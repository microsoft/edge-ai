import { readFile } from "node:fs/promises";
import { createCanvas, CanvasError, joinSession } from "@microsoft/copilot-sdk/extension";
import { createInstallerStore, startInstallerServer } from "./server.mjs";

const declaration = JSON.parse(await readFile(new URL("./extension.json", import.meta.url), "utf8"));
const instances = new Map();
const opening = new Map();

function asCanvasError(error) {
  if (error instanceof CanvasError) {
    return error;
  }
  return new CanvasError("internal", error?.message || String(error));
}

function requireInstance(instanceId) {
  const instance = instances.get(instanceId);
  if (!instance) {
    throw new CanvasError("not_open", `Canvas instance ${instanceId} is not open.`);
  }
  return instance;
}

function workingDirectory(context) {
  const directory = context.session?.workingDirectory;
  if (typeof directory !== "string" || !directory.trim()) {
    throw new CanvasError(
      "workspace_unavailable",
      "The active session working directory is unavailable.",
    );
  }
  return directory;
}

function instanceIdentity(context) {
  return `${workingDirectory(context)}\0${context.input?.state || ""}`;
}

async function startInstance(context) {
  const store = await createInstallerStore(
    workingDirectory(context),
    context.input?.state,
  );
  const server = await startInstallerServer({
    store,
    log: (message) => session.log(`[edge-ai-aio-installer] ${message}`, {
      level: "warning",
      ephemeral: true,
    }),
  });
  return { identity: store.identity, store, server };
}

async function stopInstance(instanceId) {
  const instance = instances.get(instanceId);
  instances.delete(instanceId);
  if (instance) {
    await instance.server.close();
  }
}

const actionHandlers = {
  refresh: async ({ instanceId }) => requireInstance(instanceId).store.snapshot(),
  get_state: async ({ instanceId }) => requireInstance(instanceId).store.snapshot(),
  get_feedback: async ({ instanceId }) => requireInstance(instanceId).store.getFeedback(),
  acknowledge_feedback: async ({ instanceId, input }) => (
    requireInstance(instanceId).store.acknowledgeFeedback(input?.revision)
  ),
};

const canvases = declaration.canvases.map((canvas) => createCanvas({
  ...canvas,
  actions: canvas.actions.map((action) => ({
    ...action,
    handler: async (context) => {
      try {
        return await actionHandlers[action.name](context);
      } catch (error) {
        throw asCanvasError(error);
      }
    },
  })),
  open: async (context) => {
    try {
      const identity = instanceIdentity(context);
      const current = instances.get(context.instanceId);
      if (current && current.identity === identity) {
        return { url: current.server.url, title: "AIO Installer" };
      }
      const pending = opening.get(context.instanceId);
      if (pending && pending.identity === identity) {
        const instance = await pending.promise;
        return { url: instance.server.url, title: "AIO Installer" };
      }
      if (pending) {
        pending.cancelled = true;
      }
      if (current) {
        await stopInstance(context.instanceId);
      }
      const entry = {
        identity,
        cancelled: false,
        promise: null,
      };
      entry.promise = startInstance(context).then(async (instance) => {
        if (entry.cancelled) {
          await instance.server.close();
          throw new CanvasError(
            "cancelled",
            "The canvas was closed or reopened while it was starting.",
          );
        }
        return { ...instance, identity };
      });
      opening.set(context.instanceId, entry);
      try {
        const instance = await entry.promise;
        instances.set(context.instanceId, instance);
        return { url: instance.server.url, title: "AIO Installer" };
      } finally {
        if (opening.get(context.instanceId) === entry) {
          opening.delete(context.instanceId);
        }
      }
    } catch (error) {
      throw asCanvasError(error);
    }
  },
  onClose: async ({ instanceId }) => {
    const pending = opening.get(instanceId);
    if (pending) {
      pending.cancelled = true;
    }
    await stopInstance(instanceId);
  },
}));

const session = await joinSession({ canvases });