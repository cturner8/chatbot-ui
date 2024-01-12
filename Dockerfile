# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/go/dockerfile-reference/

ARG NODE_VERSION=lts

FROM node:${NODE_VERSION}-alpine as dev

# Use production node environment by default.
ENV NODE_ENV development

WORKDIR /usr/src/app

COPY package*.json .

# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.npm to speed up subsequent builds.
# Leverage a bind mounts to package.json and package-lock.json to avoid having to copy them into
# into this layer.
RUN --mount=type=cache,target=/root/.npm \
    # --mount=type=bind,source=package.json,target=package.json \
    # --mount=type=bind,source=package-lock.json,target=package-lock.json \
    npm ci
    # npm ci --omit=dev
    # npm install 

# Run the application as a non-root user.
# USER node

# Copy the rest of the source files into the image.
COPY . .

# Expose the port that the application listens on.
EXPOSE 3000

# Run the application.
CMD npm run dev
