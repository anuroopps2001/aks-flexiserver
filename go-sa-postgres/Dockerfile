# Build Stage
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY src/go.mod src/go.sum ./
RUN go mod download
COPY src/. .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# Run Stage
FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]