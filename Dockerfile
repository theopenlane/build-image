FROM golang:1.23.4-alpine

RUN apk add git npm --no-cache  && apk cache clean \
	&& go install github.com/go-task/task/v3/cmd/task@main \
	&& go install entgo.io/ent/cmd/ent@latest \
	&& go install github.com/oNaiPs/go-generate-fast@latest \
	&& apk --update add jq \
	&& npm install jsonschema2mk --global \
	&& npm install @apollo/rover --global 


ADD https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh /tmp/install.sh

RUN chmod +x /tmp/install.sh && /tmp/install.sh v1.63.4

COPY --from=vektra/mockery:v2 /usr/local/bin/mockery /bin/mockery

COPY --from=hairyhenderson/gomplate:stable /gomplate /bin/gomplate


COPY --from=buildkite/agent:3 /usr/local/bin/buildkite-agent /bin/buildkite-agent

COPY . .

