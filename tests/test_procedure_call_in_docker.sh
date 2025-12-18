#!/bin/bash
# Script to test the CALL statement parsing bug in a Docker container

echo "Building Docker image..."
docker build -f Dockerfile.test -t piggly-procedure-test ..

echo ""
echo "Running test..."
MSYS_NO_PATHCONV=1 docker run --rm piggly-procedure-test ruby /app/tests/test_procedure_call_bug.rb

