#!/usr/bin/env node
// LSP daemon — spawns typescript-language-server, exposes Unix socket for hooks.
// Usage: node lsp-daemon.mjs <projectRoot>

import { spawn } from "node:child_process";
import { createServer } from "node:net";
import { writeFileSync, unlinkSync } from "node:fs";
const projectRoot = process.argv[2];
if (!projectRoot) {
  console.error("Usage: node lsp-daemon.mjs <projectRoot>");
  process.exit(1);
}

const socketPath = `/tmp/cc-tslsp-${process.pid}.sock`;
const infoPath = "/tmp/cc-tslsp-info.json";

// --- LSP JSON-RPC encoding/decoding ---

function encode(msg) {
  const json = JSON.stringify(msg);
  return `Content-Length: ${Buffer.byteLength(json)}\r\n\r\n${json}`;
}

class LSPReader {
  constructor() {
    this.buf = Buffer.alloc(0);
    this.handlers = [];
  }

  onMessage(fn) {
    this.handlers.push(fn);
  }

  feed(chunk) {
    this.buf = Buffer.concat([this.buf, chunk]);
    while (true) {
      const headerEnd = this.buf.indexOf("\r\n\r\n");
      if (headerEnd === -1) break;
      const header = this.buf.subarray(0, headerEnd).toString();
      const match = header.match(/Content-Length:\s*(\d+)/i);
      if (!match) break;
      const len = parseInt(match[1], 10);
      const bodyStart = headerEnd + 4;
      if (this.buf.length < bodyStart + len) break;
      const body = this.buf.subarray(bodyStart, bodyStart + len).toString();
      this.buf = this.buf.subarray(bodyStart + len);
      try {
        const msg = JSON.parse(body);
        for (const fn of this.handlers) fn(msg);
      } catch {}
    }
  }
}

// --- Spawn LSP ---

const lsp = spawn("tsgo", ["--lsp"], {
  cwd: projectRoot,
  env: { ...process.env },
  stdio: ["pipe", "pipe", "pipe"],
});

lsp.stderr.on("data", () => {});

lsp.on("exit", (code) => {
  cleanup();
  process.exit(code ?? 1);
});

const reader = new LSPReader();
lsp.stdout.on("data", (chunk) => reader.feed(chunk));

// --- LSP message tracking ---

let nextId = 1;
const pendingRequests = new Map(); // id -> { resolve }
const diagnosticWaiters = new Map(); // uri -> { resolve, timer }
const latestDiagnostics = new Map(); // uri -> diagnostics[]
const openFiles = new Set(); // uris we've sent didOpen for

function sendRequest(method, params) {
  return new Promise((resolve) => {
    const id = nextId++;
    pendingRequests.set(id, { resolve });
    lsp.stdin.write(encode({ jsonrpc: "2.0", id, method, params }));
  });
}

function sendNotification(method, params) {
  lsp.stdin.write(encode({ jsonrpc: "2.0", method, params }));
}

reader.onMessage((msg) => {
  // Response to a request
  if (msg.id != null && pendingRequests.has(msg.id)) {
    const { resolve } = pendingRequests.get(msg.id);
    pendingRequests.delete(msg.id);
    resolve(msg.result ?? msg.error);
    return;
  }
  // Notification
  if (msg.method === "textDocument/publishDiagnostics") {
    const { uri, diagnostics } = msg.params;
    latestDiagnostics.set(uri, diagnostics);
    const waiter = diagnosticWaiters.get(uri);
    if (waiter) {
      clearTimeout(waiter.timer);
      diagnosticWaiters.delete(uri);
      waiter.resolve(diagnostics);
    }
  }
});

// --- Initialize LSP ---

async function initializeLSP() {
  const result = await sendRequest("initialize", {
    processId: process.pid,
    rootUri: `file://${projectRoot}`,
    rootPath: projectRoot,
    capabilities: {
      textDocument: {
        publishDiagnostics: { relatedInformation: true },
        synchronization: {
          didOpen: true,
          didChange: true,
          willSave: false,
          didSave: true,
        },
      },
      workspace: {
        workspaceFolders: true,
      },
    },
    workspaceFolders: [
      { uri: `file://${projectRoot}`, name: "root" },
    ],
  });

  sendNotification("initialized", {});
  return result;
}

// --- File checking ---

let fileVersion = new Map(); // uri -> version counter

function getVersion(uri) {
  const v = (fileVersion.get(uri) ?? 0) + 1;
  fileVersion.set(uri, v);
  return v;
}

function waitForDiagnostics(uri, timeoutMs = 2000) {
  return new Promise((resolve) => {
    // If we already have fresh diagnostics, resolve immediately
    const timer = setTimeout(() => {
      diagnosticWaiters.delete(uri);
      // Return whatever we have (could be stale or empty)
      resolve(latestDiagnostics.get(uri) ?? []);
    }, timeoutMs);

    diagnosticWaiters.set(uri, { resolve, timer });
  });
}

async function checkFile(filePath, content) {
  const uri = `file://${filePath}`;
  const languageId = filePath.endsWith(".tsx") ? "typescriptreact" : "typescript";

  if (!openFiles.has(uri)) {
    openFiles.add(uri);
    sendNotification("textDocument/didOpen", {
      textDocument: {
        uri,
        languageId,
        version: getVersion(uri),
        text: content,
      },
    });
  } else {
    sendNotification("textDocument/didChange", {
      textDocument: { uri, version: getVersion(uri) },
      contentChanges: [{ text: content }],
    });
  }

  const diagnostics = await waitForDiagnostics(uri);
  return diagnostics;
}

// --- Unix socket server ---

const server = createServer({ allowHalfOpen: true }, (socket) => {
  let data = "";
  socket.on("data", (chunk) => (data += chunk));
  socket.on("end", async () => {
    try {
      const cmd = JSON.parse(data);
      if (cmd.type === "check") {
        const diagnostics = await checkFile(cmd.filePath, cmd.content);
        socket.write(JSON.stringify(diagnostics));
        socket.end();
      } else if (cmd.type === "ping") {
        socket.write(JSON.stringify({ ok: true }));
        socket.end();
      } else {
        socket.write(JSON.stringify({ error: "unknown command" }));
        socket.end();
      }
    } catch (e) {
      socket.write(JSON.stringify({ error: e.message }));
      socket.end();
    }
  });
});

function cleanup() {
  try { unlinkSync(socketPath); } catch {}
  try { unlinkSync(infoPath); } catch {}
}

process.on("SIGTERM", () => {
  sendNotification("shutdown", null);
  sendNotification("exit", null);
  lsp.kill();
  cleanup();
  process.exit(0);
});

process.on("SIGINT", () => {
  cleanup();
  process.exit(0);
});

// --- Start ---

await initializeLSP();

server.listen(socketPath, () => {
  writeFileSync(infoPath, JSON.stringify({ socketPath, pid: process.pid }));
  // Signal ready on stdout so the start hook knows we're up
  console.log("READY");
});
