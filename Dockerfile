#### BASE
FROM node:latest AS base
WORKDIR /app

# Install moon binary
RUN npm install -g @moonrepo/cli

#### WORKSPACE
FROM base AS workspace
WORKDIR /app

# Copy entire repository and scaffold
COPY . .
RUN moon docker scaffold my-app

#### BUILD
FROM base AS build
WORKDIR /app

# Copy workspace skeleton
COPY --from=workspace /app/.moon/docker/workspace .

# Install toolchain and dependencies
RUN moon docker setup

# Copy source files
COPY --from=workspace /app/.moon/docker/sources .

# Run build
RUN moon run :build

COPY apps/my-app/.next/standalone .
COPY apps/my-app/.next/static ./.next/static
COPY apps/my-app/public ./public

# Prune workspace
RUN moon docker prune

### Runtime
FROM node:20-alpine AS runtime
WORKDIR /app

COPY --from=build /app .

EXPOSE 3000

ENV PORT 3000

CMD HOSTNAME="0.0.0.0" node server.js
