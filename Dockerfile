# first, we pull the latest go image to build our go application in
FROM golang:latest AS builder

ENV logbook_version 0.0.1

## Fetch the sources from github
RUN go get -d -v github.com/alexgunkel/logbook \
    && cd $GOPATH/src/github.com/alexgunkel/logbook \
    # Checkout the tagged version
    && git checkout ${logbook_version} \
    #
    # that's not really a ci-pipeline, but at least
    # we run the unit tests once to ensure that a valid
    # version has been downloaded from github
    #
    # Before we can run the tests, we need to install
    # the required packages
    && go get -d -v github.com/stretchr/testify \
    && go get -d -v github.com/posener/wstest \
    && go test ./... \
    # now build the application
    # CGO_ENABLES=0 we don't need to compile c code
    # GOOS=linux    os is linux, of course
    # -a            we force rebuilding of all packages
    # -o logbook    make the resulting file name explicit
    && CGO_ENABLED=0 GOOS=linux go build -a -o logbook .

# We need git for logbook-frontend, but the node-image doesn't provide git
# rather than installing git in the node-container we simply pull a git-image
FROM alpine/git AS git
WORKDIR /logbook-frontent
RUN git clone https://github.com/XenosEleatikos/logbook-frontend /logbook-frontend

# build the angular sources
FROM node:8-alpine AS angular
RUN npm set progress=false && npm config set depth 0 && npm cache clean --force
WORKDIR /logbook-frontend
COPY --from=git /logbook-frontend/ .
RUN npm i \
  && npm install -g @angular/cli \
  && ng build \
  && mv ./dist/index.html ./dist/Index.html \
  && sed -i -e 's|<base href="/">|<base href="{{.PathToStatic}}">|g' ./dist/Index.html\
  && sed -i -e 's|wss://echo.websocket.org|{{.Uri}}|g' ./dist/*

# finally, put all things together and build a small app-image
FROM alpine:latest
#RUN mkdir -p /backend/public \
#  && mkdir -p /frontend \
#  && mkdir /app
WORKDIR /app
COPY --from=builder /go/src/github.com/alexgunkel/logbook/logbook /backend/
COPY --from=angular /logbook-frontend/dist /frontend
COPY ./entrypoint.sh /app/run.sh

EXPOSE 8080

CMD ["/app/run.sh"]
