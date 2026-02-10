---
description: "Profile Node.js application performance: identify bottlenecks, event loop blocking, and common anti-patterns"
---

# node-perf

Profile a Node.js application for performance issues by scanning for common anti-patterns, event loop blocking, and missed optimization opportunities.

## Process

1. Check if the project has any performance-related scripts or configurations
2. Scan source files for common performance anti-patterns:
   - Synchronous fs/crypto calls in request handlers or hot paths
   - JSON.parse/stringify on large payloads without streaming
   - Missing connection pooling for databases
   - Unbounded Promise.all without concurrency limits
   - Large regex or string operations that may block the event loop
   - Missing stream backpressure handling
3. Check for unoptimized dependencies (known slow packages with faster alternatives)
4. Suggest Node.js runtime flags for performance tuning (--max-old-space-size, --max-semi-space-size)
5. Provide guidance on running V8 profiler with --prof and processing output with --prof-process
6. Reference the diagnosing-node skill for deeper CPU and memory profiling
