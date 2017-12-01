# first, we pull the latest go image to build our go application in
FROM golang:latest AS builder
RUN go get -d -v github.com/alexgunkel/logbook \
    && cd $GOPATH/src/github.com/alexgunkel/logbook \
    && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o logbook .

# We need git for logbook-frontend, but the node-image doesn't provide git
# rather than installing git in the node-container we simply pull a git-image
FROM alpine/git AS git
WORKDIR /logbook-frontent
RUN git clone https://github.com/XenosEleatikos/logbook-frontend /logbook-frontend

# Pull and build the angular sources
FROM node:8-alpine AS angular
RUN npm set progress=false && npm config set depth 0 && npm cache clean --force
WORKDIR /logbook-frontend
COPY --from=git /logbook-frontend/ .
RUN npm i \
  && npm install -g @angular/cli \
  && ng build

# finally, put all things together and build a small app-image
FROM alpine:latest
RUN apk --no-cache add ca-certificates \
  && mkdir -p /app/resources/private/template \
  && mkdir -p /frontend
WORKDIR /app
COPY --from=builder /go/src/github.com/alexgunkel/logbook/logbook .
COPY --from=builder /go/src/github.com/alexgunkel/logbook/resources/private/template/Index.html ./resources/private/template/
COPY --from=angular /logbook-frontend/dist /angular
COPY ./entrypoint.sh /run/entrypoint.sh

EXPOSE 8080

CMD ["/run/entrypoint.sh"]
