package main

import (
	"context"
	ddlambda "github.com/DataDog/datadog-lambda-go"
	"github.com/aws/aws-lambda-go/lambda"
	awscfg "github.com/aws/aws-sdk-go-v2/config"
	awstrace "gopkg.in/DataDog/dd-trace-go.v1/contrib/aws/aws-sdk-go-v2/aws"
	"log"
)

func main() {
	lambda.Start(ddlambda.WrapFunction(FunctionHandler, nil))
}

func FunctionHandler(ctx context.Context) (int, error) {
	awsCfg, _ := awscfg.LoadDefaultConfig(context.Background())
	awstrace.AppendMiddleware(&awsCfg)
	log.Println("Hello World!")

	return 200, nil
}
