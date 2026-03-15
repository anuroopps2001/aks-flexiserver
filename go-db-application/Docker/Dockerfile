FROM golang:1.24.11-alpine3.23 AS builder

ENV CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64


# Set working directory inside the container
WORKDIR /app

# Copy go.mod and go.sum files for dependency installation into workdir
COPY . .  
# Based on the build context for Jenkins, build context has been modified in Jenkinsfile


# To download dependencies required to run go application
RUN go mod download


# Copy the entire application source
COPY . .

RUN go build -o app

FROM alpine:3.21 

WORKDIR /app

COPY --from=builder /app/app .

# Check server.go for application listening port details
EXPOSE 8080

CMD [ "./app" ]


