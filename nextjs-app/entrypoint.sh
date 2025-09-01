#!/bin/sh

# Run Prisma migrations on startup
echo "Running Prisma migrations..."
bunx prisma migrate deploy

# Start the application
echo "Starting Next.js application..."
exec bun run server.js