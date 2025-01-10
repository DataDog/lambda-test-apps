package main

import (
	"context"
	ddlambda "github.com/DataDog/datadog-lambda-go"
	"github.com/aws/aws-lambda-go/lambda"
	"log"
)

func main() {
	lambda.Start(ddlambda.WrapFunction(FunctionHandler, nil))
}

func FunctionHandler(ctx context.Context) (int, error) {
	log.Println("Hello World!")

	return 200, nil
}
