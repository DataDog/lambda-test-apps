# Config
export SERVICE="nhulston-go-test" # used to name your Lambda function
PROJECT_PATH="$HOME/Dev/Misc/lambda-test-apps/Golang/" # path to this directory
EXTENSION_PATH="$HOME/Dev/Rust/datadog-lambda-extension/"
EXTENSION_LAYER_NAME="nhulston-datadog-extension" # name of your custom Lambda extension layer
ARCH="amd64" # arch of your Lambda. amd64 (default) or arm64
# Make sure you update the `go.mod` file to pull in your changes to dd-trace-go!
# Also update the datadog-lambda-go version in `go.mod`

# Other constants
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_PAGER=""

cd src
go get
go mod tidy
cd ../
npm install

# Validate required vars
if [ -z "$BUILD_EXTENSION" ]; then
    echo "Error: BUILD_EXTENSION flag must be set"
    echo "Usage: BUILD_EXTENSION=true|false ./build.sh"
    exit 1
fi

if [ "$BUILD_EXTENSION" = "true" ]; then
    # Build agent
    echo "Building bottlecap extension..."
    cd $EXTENSION_PATH
    cd bottlecap-run
    ARCH=$ARCH ./bottlecap_dev.sh build_dockerized
    cd ../.layers

    # Upload extension layer
    echo "Publishing bottlecap extension layer..."
    EXTENSION_LAYER_VERSION=$(aws lambda publish-layer-version \
        --layer-name $EXTENSION_LAYER_NAME \
        --zip-file fileb://datadog_bottlecap-${ARCH}.zip \
        --query Version \
        --output text)
else
    echo "Fetching latest bottlecap extension layer version..."
    EXTENSION_LAYER_VERSION=$(aws lambda list-layer-versions \
        --layer-name $EXTENSION_LAYER_NAME \
        --query 'LayerVersions[0].Version' \
        --output text)
fi
export EXTENSION_LAYER_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:layer:${EXTENSION_LAYER_NAME}:${EXTENSION_LAYER_VERSION}"
echo "Extension Layer ARN: $EXTENSION_LAYER_ARN"

# Build and Deploy
echo 'Building Go binary...'
cd $PROJECT_PATH
cd src
GOOS=linux GOARCH=$ARCH go build -tags lambda.norpc -o bootstrap main.go
mkdir -p ../target
mv bootstrap ../target
cd ../target
zip function.zip bootstrap
echo 'Deploying Lambda...'
cd ../
serverless deploy
#serverless deploy function -f main
