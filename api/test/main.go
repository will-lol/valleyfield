package main

import (
	"context"
	"errors"
	"fmt"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func HandleEvent(ctx context.Context, event *events.APIGatewayProxyRequest) (*events.APIGatewayProxyResponse, error) {
	if event == nil {
		return nil, errors.New("Received nil event")
	}
	return &events.APIGatewayProxyResponse{Body: fmt.Sprintf("Hello %s!", event.Body), StatusCode: 200}, nil
}

func main() {
	lambda.Start(HandleEvent)
}
