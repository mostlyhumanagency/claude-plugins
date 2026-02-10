#!/usr/bin/env node
// PostToolUse hook: check TypeScript diagnostics after Edit/Write on .ts/.tsx files.

import { createConnection } from "node:net";
import { readFileSync } from "node:fs";

const input = await new Promise((resolve) => {
  let data = "";
  process.stdin.on("data", (chunk) => (data += chunk));
  process.stdin.on("end", () => resolve(JSON.parse(data)));
});

const filePath = input.tool_input?.file_path;
if (!filePath) process.exit(0);

// Only check .ts and .tsx files
if (!filePath.endsWith(".ts") && !filePath.endsWith(".tsx")) {
  process.exit(0);
}

// Skip declaration files
if (filePath.endsWith(".d.ts")) {
  process.exit(0);
}

// Find socket path
const socketPath =
  process.env.CC_TSLSP_SOCK ||
  (() => {
    try {
      const info = JSON.parse(readFileSync("/tmp/cc-tslsp-info.json", "utf8"));
      return info.socketPath;
    } catch {
      return null;
    }
  })();

if (!socketPath) process.exit(0);

// Read current file content from disk (post-edit)
let content;
try {
  content = readFileSync(filePath, "utf8");
} catch {
  process.exit(0);
}

// Connect to daemon and request diagnostics
function queryDaemon(sock, payload) {
  return new Promise((resolve, reject) => {
    const conn = createConnection(sock, () => {
      conn.write(JSON.stringify(payload));
      conn.end();
    });
    let data = "";
    conn.on("data", (chunk) => (data += chunk));
    conn.on("end", () => {
      try {
        resolve(JSON.parse(data));
      } catch (e) {
        reject(e);
      }
    });
    conn.on("error", (e) => reject(e));
    // Timeout
    setTimeout(() => {
      conn.destroy();
      reject(new Error("timeout"));
    }, 3000);
  });
}

try {
  const diagnostics = await queryDaemon(socketPath, {
    type: "check",
    filePath,
    content,
  });

  if (!Array.isArray(diagnostics) || diagnostics.length === 0) {
    process.exit(0);
  }

  // Filter to errors and warnings only
  const significant = diagnostics.filter((d) => d.severity <= 2);
  if (significant.length === 0) {
    process.exit(0);
  }

  // Format diagnostics
  const fileName = filePath.split("/").pop();
  const lines = significant.map((d) => {
    const line = (d.range?.start?.line ?? 0) + 1;
    const col = (d.range?.start?.character ?? 0) + 1;
    const sev = d.severity === 1 ? "error" : "warning";
    const code = d.code != null ? ` [TS${d.code}]` : "";
    return `  ${fileName}:${line}:${col} - ${sev}${code}: ${d.message}`;
  });

  const output = {
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: `TypeScript diagnostics after edit:\n${lines.join("\n")}`,
    },
  };

  process.stdout.write(JSON.stringify(output));
  process.exit(0);
} catch {
  // Daemon unreachable or error — fail silently
  process.exit(0);
}
