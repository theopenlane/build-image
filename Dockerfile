FROM golang:1.24.2-alpine AS builder

# Install dependencies and tools
RUN apk --no-cache add --virtual .build-deps \
        git npm gcc musl-dev curl jq \
    && (go install github.com/go-task/task/v3/cmd/task@main \
    && go install entgo.io/ent/cmd/ent@latest \
    && go install github.com/oNaiPs/go-generate-fast@latest) \
	&& wait \
    && npm install jsonschema2mk --global \
    && npm install @apollo/rover --global \
	&& git config --global --add safe.directory '*' \
    && curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh -o /tmp/install.sh \
    && chmod +x /tmp/install.sh \
    && /tmp/install.sh v2.1.6 \
    && apk del .build-deps \
    && rm -rf /tmp/* /var/cache/apk/*

# Copy tools from other images
COPY --from=vektra/mockery:3 /usr/local/bin/mockery /bin/mockery
COPY --from=hairyhenderson/gomplate:stable /gomplate /bin/gomplate
COPY --from=buildkite/agent:3 /usr/local/bin/buildkite-agent /bin/buildkite-agent

# Final stage
FROM golang:1.24.2-alpine

RUN apk --no-cache add \
		gcc musl-dev

# Copy only necessary files from the builder stage
COPY --from=builder /bin/mockery /bin/mockery
COPY --from=builder /bin/gomplate /bin/gomplate
COPY --from=builder /bin/buildkite-agent /bin/buildkite-agent
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application source code
COPY . .

