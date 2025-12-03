#!/bin/bash
# Script to test the encoding bug in a Docker container

# Build a temporary Docker image with the piggly_project code
docker build -f Dockerfile.test -t piggly-encoding-test ..

# Run the test script
MSYS_NO_PATHCONV=1 docker run --rm piggly-encoding-test ruby /app/tests/test_encoding_bug.rb

