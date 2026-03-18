FROM golang:1.23-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git

COPY src/go.mod src/go.sum ./

RUN go mod download

COPY src/ .


# Build an executable binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o app

# ---------- Runtime stage ----------
FROM alpine:3.19

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /app/app .

# Set Permissions
RUN chown -R 0:0 /app && chmod -R g+rwX /app  # assign the permissions on source code


# Expose non-root port
EXPOSE 8080

# Run App
CMD ["./app"]
