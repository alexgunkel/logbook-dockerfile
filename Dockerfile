# first, we pull the latest go image to build our go application in
FROM golang:latest AS builder
RUN go get -d -v github.com/alexgunkel/logbook \
    && cd $GOPATH/src/github.com/alexgunkel/logbook \
    && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o logbook .

# finally, put all things together and build a small app-image
FROM alpine:latest
RUN mkdir -p /backend/public \
  && mkdir -p /frontend \
  && mkdir /app
WORKDIR /app
COPY --from=builder /go/src/github.com/alexgunkel/logbook/logbook /backend/
COPY --from=builder /go/src/github.com/alexgunkel/logbook/public/Index.html /backend/public/
COPY ./run.sh /app/run.sh

EXPOSE 8080

CMD ["/app/run.sh"]
