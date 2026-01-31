FROM golang:1.25.6-alpine AS builder

# ensure the go install directory is in the PATH
ARG GOBIN=/usr/local/bin/
# ensure he golangci-lint install directory is in the PATH
ARG BINDIR=/usr/local/bin/

# Install dependencies and tools
RUN apk --no-cache add --virtual .build-deps \
        npm curl \
    && (go install github.com/go-task/task/v3/cmd/task@main \
    && go install entgo.io/ent/cmd/ent@latest \
    && go install github.com/mikefarah/yq/v4@latest) \
	&& wait \
    && npm install -g jsonschema2mk \
    && npm install -g @apollo/rover \
    && curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh -o /tmp/install.sh \
    && chmod +x /tmp/install.sh \
    && /tmp/install.sh v2.6.2 \
    && apk del .build-deps \
    && rm -rf /tmp/* /var/cache/apk/*

# Copy tools from other images
COPY --from=vektra/mockery:3 /usr/local/bin/mockery /bin/mockery
COPY --from=hairyhenderson/gomplate:stable /gomplate /bin/gomplate
COPY --from=buildkite/agent:3 /usr/local/bin/buildkite-agent /bin/buildkite-agent

# Final stage
FROM golang:1.25.6-alpine

RUN apk --no-cache add \
		gcc musl-dev curl jq git npm github-cli bash openssh-client

# Copy only necessary files from the builder stage
COPY --from=builder /bin/mockery /bin/mockery
COPY --from=builder /bin/gomplate /bin/gomplate
COPY --from=builder /bin/buildkite-agent /bin/buildkite-agent
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin /usr/local/bin

RUN git config --global --add safe.directory '*'

# Copy application source code
COPY . .
