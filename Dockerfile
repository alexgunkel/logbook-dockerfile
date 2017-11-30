FROM golang:latest AS builder
RUN go get -d -v github.com/alexgunkel/logbook \
    && cd $GOPATH/src/github.com/alexgunkel/logbook \
    && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o logbook .

FROM alpine/git AS git
WORKDIR /logbook-frontent
RUN git clone https://github.com/XenosEleatikos/logbook-frontend /logbook-frontend

FROM node:8-alpine AS angular
RUN npm set progress=false && npm config set depth 0 && npm cache clean --force
WORKDIR /logbook-frontend
COPY --from=git /logbook-frontend/ .
RUN npm i \
  && npm install -g @angular/cli \
  && ng build

FROM alpine:latest
RUN apk --no-cache add ca-certificates \
  && mkdir -p /root/resources/private/template \
  && mkdir -p /angular-frontend
WORKDIR /root/
COPY --from=builder /go/src/github.com/alexgunkel/logbook/logbook .
COPY --from=builder /go/src/github.com/alexgunkel/logbook/resources/private/template/Index.html ./resources/private/template/
COPY --from=angular /logbook-frontend/dist /angular
CMD ["./logbook"]
