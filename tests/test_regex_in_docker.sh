#!/bin/bash
# Script to test the regex escape fix in Ruby 3.4 Docker container

set -e

echo "Building Docker image with Ruby 3.4..."
docker build -f Dockerfile.test -t piggly-regex-test ..

echo ""
echo "Running regex escape test in Ruby 3.4 container..."
echo "=================================================="
MSYS_NO_PATHCONV=1 docker run --rm piggly-regex-test ruby /app/tests/test_regex_bug.rb

echo ""
echo "Test completed successfully!"

