package main

import (
	"github.com/aws-lambda-canary-demo/internal/hello"
	"github.com/aws/aws-lambda-go/lambda"
)

func main() {
	helloService := hello.NewHelloService("v2")

	lambda.Start(helloService.SayHello)
}
