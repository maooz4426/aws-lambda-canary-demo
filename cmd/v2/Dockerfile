FROM golang:1.26.1 as build
WORKDIR /app
COPY go.mod go.sum ./
COPY vendor/ ./vendor/
COPY internal/ ./internal/
COPY cmd/ ./cmd/
RUN go build -mod vendor -o main cmd/v2/main.go

FROM public.ecr.aws/lambda/provided:al2023
COPY --from=build /app/main ./main
ENTRYPOINT [ "./main"]
