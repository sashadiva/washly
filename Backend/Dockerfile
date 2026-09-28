# Washly backend – development image
# Node 22 matches what's on the host and satisfies the toolchain (tsx, Prisma 7).
FROM node:22-slim

# Prisma needs OpenSSL present in the image to generate/run its query engine.
RUN apt-get update -y && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install dependencies first so this layer is cached unless the manifests change.
COPY package.json package-lock.json ./
RUN npm install

# Copy the rest of the source (node_modules is excluded via .dockerignore).
COPY . .

# Generate the Prisma client inside the container against the schema.
# generate() doesn't connect to the DB, but prisma.config.ts resolves
# env("DATABASE_URL"), so provide a throwaway value just for this step.
RUN DATABASE_URL="postgresql://build:build@localhost:5432/build" npx prisma generate

EXPOSE 5000

# Hot-reloading dev server. Source is bind-mounted in docker-compose so edits
# on the host are picked up live.
CMD ["npm", "run", "dev"]
