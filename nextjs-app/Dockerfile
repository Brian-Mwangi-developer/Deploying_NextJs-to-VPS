FROM oven/bun:alpine AS base

# Stage 1: Install Dependencies
FROM base AS deps
WORKDIR /app
COPY package.json bun.lock ./
COPY prisma/ ./prisma/
RUN bun install --frozen-lockfile

# Stage 2: Build the Application
FROM base AS builder
WORKDIR /app

# Copy dependencies
COPY --from=deps /app/node_modules ./node_modules

# Copy all necessary files for Next.js build
COPY package.json ./
COPY src/ ./src/
COPY prisma/ ./prisma/
COPY public/ ./public/
COPY next.config.js ./
COPY tsconfig.json ./
COPY .env* ./
COPY postcss.config.js ./
COPY tailwind.config.* ./
COPY .eslintrc.* ./
COPY prettier.config.js ./

# Build the application
RUN bunx prisma generate
RUN bun run build

# Stage 3: Production Server
FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy built application
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Copy Prisma files for runtime
COPY --from=builder --chown=nextjs:nodejs /app/prisma ./prisma
COPY --from=builder --chown=nextjs:nodejs /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder --chown=nextjs:nodejs /app/node_modules/@prisma ./node_modules/@prisma

COPY entrypoint.sh ./
RUN chown nextjs:nodejs entrypoint.sh && chmod +x entrypoint.sh


USER nextjs

EXPOSE 3000

ENTRYPOINT ["./entrypoint.sh"]