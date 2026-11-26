# syntax=docker/dockerfile:1
# One image runs the API, the dashboard and the Solid Queue worker (inside Puma).

# 1. Dashboard
FROM node:24.22.2-bookworm-slim@sha256:01d566e8d94d8c619591d78652babfccd3c6992a3dffa9ed5ab39e11cf6c70e9 AS dashboard
WORKDIR /app/frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci --ignore-scripts
COPY frontend/ ./
RUN npm run build

# 2. Shared base. Ruby 3.3.14 is the first 3.3 release with the CVE-2026-132825 fix.
FROM ruby:3.3.14-slim-bookworm@sha256:b5a2eaadcdde89e3ccbe9113ba23c9e890a6381f4e928bc76e3c91423a325452 AS base
WORKDIR /rails
ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test"

# 3. Gems, built with compilers that stay out of the final image
FROM base AS gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# 4. Runtime
FROM base
COPY --from=gems "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY . .
COPY --from=dashboard /app/public/dashboard public/dashboard
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p storage tmp log && \
    chown -R rails:rails storage tmp log
USER 1000:1000

ENV SOLID_QUEUE_IN_PUMA=1 \
    PORT=3000
EXPOSE 3000
ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
