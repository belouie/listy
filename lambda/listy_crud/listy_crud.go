package main

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

type Response events.APIGatewayProxyResponse

type LambdaResponse struct {
	Message string
}

func HandleRequest(ctx context.Context, event events.APIGatewayCustomAuthorizerRequest) (Response, error) {
	fmt.Printf("%v\n", event)

	lambdaResponse := LambdaResponse{
		Message: "Hello from Lambda!",
	}

	response, err := json.Marshal(lambdaResponse)

	res := Response{
		StatusCode:      200,
		IsBase64Encoded: false,
		Headers: map[string]string{
			"Access-Control-Allow-Origin":      "*",
			"Access-Control-Allow-Credentials": "true",
			"Cache-Control":                    "no-cache; no-store",
			"Content-Type":                     "application/json",
			"Content-Security-Policy":          "default-src self",
			"Strict-Transport-Security":        "max-age=31536000; includeSubDomains",
			"X-Content-Type-Options":           "nosniff",
			"X-XSS-Protection":                 "1; mode=block",
			"X-Frame-Options":                  "DENY",
		},
		Body: string(response),
	}

	return res, err
}

func main() {
	lambda.Start(HandleRequest)
}
