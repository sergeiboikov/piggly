#!/bin/bash
# Script to test the PROCEDURE routine kind bug in a Docker container

echo "Building Docker image..."
docker build -f Dockerfile.test -t piggly-procedure-test ..

echo ""
echo "Running procedure routine kind test..."
MSYS_NO_PATHCONV=1 docker run --rm piggly-procedure-test ruby /app/tests/test_procedure_routine_kind_bug.rb


