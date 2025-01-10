package main

import (
	"context"
	"fmt"
	ddlambda "github.com/DataDog/datadog-lambda-go"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
	awstrace "gopkg.in/DataDog/dd-trace-go.v1/contrib/aws/aws-sdk-go-v2/aws"
	"log"
)

func main() {
	lambda.Start(ddlambda.WrapFunction(FunctionHandler, nil))
}

func FunctionHandler(ctx context.Context) (int, error) {
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion("us-east-1"))
	if err != nil {
		return 500, fmt.Errorf("%v", err)
	}

	awstrace.AppendMiddleware(&cfg)
	log.Println("Hello World!")

	return 200, nil
}
