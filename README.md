## Overview

This repo is a list of Lambda functions made with the Serverless Framework used to quickly test changes to each runtime's tracer and/or Bottlecap.

## Instructions

To deploy your test app, `cd` to your runtime, go into the `build.sh` for your runtime, update the environment variables at the top, then run the script to deploy. 

Make sure you update all the required environment variables in the config section of your `build.sh` file:
- Store your Datadog API key under `DD_API_KEY` in your path (in `~/.zshrc` on Mac)
- Project paths (e.g. your path to `datadog-lambda-extension` and the tracer path you're testing)
- A unique service name so you don't overwrite someone else's test app
- Unique layer names so you don't overwrite someone else's test layers
- Anything else -- each runtime might require different settings

Make sure you're using Serverless Framework v3.39.0.

Then, you can deploy:
- For Python/Node `./build.sh` will automatically build the tracer and Lambda library
- For Java/.NET, `BUILD_EXTENSION=true|false BUILD_LAYER=true|false ./build.sh` allows you to specify if you want to build the Lambda extension and/or tracer layer. If true, a new layer is build and published to our sandbox account. If false, we just use the latest version of the layer.
- For Golang, to test your changes to the tracer, you need to push your changes to a branch in `dd-trace-go` and set the branch name in `go.mod`. Then, you can deploy with `BUILD_EXTENSION=true|false ./build.sh`.

*Important*: The script deploys with `serverless deploy`, which is slow but needs to be run once. After deploying once, you can replace it with `serverless deploy function -f main` for faster iterations.