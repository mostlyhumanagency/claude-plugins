# =============================================================================
# Multi-stage Dockerfile for Node.js applications
#
# Why alpine?  Smaller image (~50MB vs ~350MB for debian). Fewer CVEs.
# Why multi-stage?  Dev dependencies stay in the builder — production image
#   only contains runtime deps and compiled output.
# Why non-root?  Principle of least privilege. The "node" user is built into
#   the official Node.js images.
# =============================================================================

# ---------------------------------------------------------------------------
# Stage 1: Builder — install all deps and compile
# ---------------------------------------------------------------------------
FROM node:24-alpine AS builder

WORKDIR /app

# Copy package manifests first to leverage Docker layer caching.
# Dependencies are re-installed only when these files change.
COPY package.json package-lock.json ./

# Use `npm ci` for clean, reproducible installs (respects lockfile exactly).
RUN npm ci

# Copy the rest of the source code
COPY . .

# Build the application (TypeScript compile, bundling, etc.)
RUN npm run build

# ---------------------------------------------------------------------------
# Stage 2: Production — minimal runtime image
# ---------------------------------------------------------------------------
FROM node:24-alpine

# Alpine ships with tini as PID 1 init, which handles signal forwarding
# correctly. If you're NOT on alpine, add `dumb-init` or `tini`:
#   RUN apk add --no-cache tini
#   ENTRYPOINT ["/sbin/tini", "--"]
# This ensures SIGTERM is forwarded to your Node process for graceful shutdown.

WORKDIR /app

# Install production dependencies only
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy built output from the builder stage.
# --chown=node:node ensures files are owned by the non-root user.
COPY --from=builder --chown=node:node /app/dist ./dist

# Run as non-root for security
USER node

# Set production environment
ENV NODE_ENV=production

# Expose the application port
EXPOSE 3000

# Health check — ensures the container is serving traffic.
# Adjust the endpoint and interval to match your application.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --spider http://localhost:3000/health || exit 1

# Start the application
CMD ["node", "dist/index.js"]
