# Build Docker (Stage 1)

FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY go.mod ./
COPY main.go ./

ARG VERSION=dev

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-X main.version=${VERSION}" \
    -o app .

# Runtime Stage (Stage 2)

FROM alpine:3.22

WORKDIR /app

COPY --from=builder /app/app .

EXPOSE 8080

ENV PORT=8080

CMD [ "./app" ]