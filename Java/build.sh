# Config
export SERVICE="nhulston-java-test" # used to name your Lambda function
PROJECT_PATH="$HOME/Dev/Misc/lambda-test-apps/Java/" # path to this directory
TRACER_PATH="$HOME/Dev/Java/dd-trace-java/"
EXTENSION_PATH="$HOME/Dev/Rust/datadog-lambda-extension/"
TRACER_LAYER_NAME="nhulston-dd-trace-java-test" # name of your custom tracer Lambda layer
EXTENSION_LAYER_NAME="nhulston-datadog-extension" # name of your custom Lambda extension layer
export TRACER_VERSION="1.45.0" # what version is your branch on? Check https://github.com/DataDog/dd-trace-java/releases
ARCH="amd64" # arch of your Lambda. amd64 (default) or arm64

# Other constants
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_PAGER=""

npm install
# Validate required vars
if [ -z "$BUILD_LAYER" ] || [ -z "$BUILD_EXTENSION" ]; then
    echo "Error: BUILD_LAYER and BUILD_EXTENSION flags must be set"
    echo "Usage: BUILD_LAYER=true|false BUILD_EXTENSION=true|false ./build.sh"
    exit 1
fi

if [ "$BUILD_LAYER" = "true" ]; then
    # Build layer
    echo 'Building layer...'
    export JAVA_HOME=$JAVA_8_HOME
    cd $TRACER_PATH
    ./gradlew publishToMavenLocal
    cd ~/.m2/repository/com/datadoghq/dd-java-agent/${TRACER_VERSION}-SNAPSHOT
    zip layer.zip dd-java-agent-${TRACER_VERSION}-SNAPSHOT.jar

    # Upload layer
    echo 'Publishing layer...'
    LAYER_VERSION=$(aws lambda publish-layer-version \
        --layer-name $TRACER_LAYER_NAME \
        --zip-file fileb://layer.zip \
        --query Version \
        --output text)
else
    echo "Fetching latest layer version..."
    LAYER_VERSION=$(aws lambda list-layer-versions \
        --layer-name $TRACER_LAYER_NAME \
        --query 'LayerVersions[0].Version' \
        --output text)
fi
export TRACER_LAYER_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:layer:${TRACER_LAYER_NAME}:${LAYER_VERSION}"
echo "Tracer layer ARN: $TRACER_LAYER_ARN"

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

# Deploy
echo 'Deploying Lambda...'
cd  $PROJECT_PATH
npm install
export JAVA_HOME=$JAVA_21_HOME
mvn package
serverless deploy
#serverless deploy function -f main
