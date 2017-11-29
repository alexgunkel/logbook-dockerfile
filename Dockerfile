FROM golang:latest AS builder
RUN go get -d -v github.com/alexgunkel/logbook \
    && cd $GOPATH/src/github.com/alexgunkel/logbook \
    && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o logbook .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /go/src/github.com/alexgunkel/logbook/logbook .
RUN mkdir -p /root/resources/private/template
COPY --from=builder /go/src/github.com/alexgunkel/logbook/resources/private/template/Index.html ./resources/private/template/
CMD ["./logbook"]
