# syntax=docker/dockerfile:1

ARG NODE_VERSION=lts

FROM node:${NODE_VERSION}-alpine as base

# 1. Install dependencies only when needed
FROM base as deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat

WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json package-lock.json* ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# 2. Rebuild the source code only when needed
FROM base as builder

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules

COPY . .

# This will do the trick, use the corresponding env file for each environment
# -> linting temporarily disabled
RUN npm run build -- --no-lint 

# 3. Production image, copy all the files and run next
FROM base as runner

WORKDIR /app

ENV NODE_ENV=production

RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

COPY --from=builder /app/public ./public

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
# COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
# COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder /app/.next ./.next


USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME localhost

# CMD ["node", "server.js"]
CMD ["npm", "start"]
