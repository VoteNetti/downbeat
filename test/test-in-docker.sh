#!/bin/bash
# Helper script for testing installation scripts in Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Testing downbeat in Docker${NC}\n"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running.${NC}"
    echo "Please start Docker Desktop and try again."
    exit 1
fi

# Build the Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
docker compose build

# Start the container
echo -e "${YELLOW}Starting test container...${NC}"
docker compose up -d

# Show instructions
echo -e "\n${GREEN}Container is ready!${NC}\n"
echo "To enter the container and test scripts:"
echo -e "  ${YELLOW}docker compose exec ubuntu-test bash${NC}"
echo ""
echo "Inside the container, you can run:"
echo -e "  ${YELLOW}bash -n install.sh${NC}  # Syntax check"
echo -e "  ${YELLOW}./install.sh${NC}        # Run installation"
echo ""
echo "To stop and remove the container:"
echo -e "  ${YELLOW}docker compose down${NC}"
echo ""
echo "To rebuild from scratch (clean state):"
echo -e "  ${YELLOW}docker compose down && docker compose build --no-cache${NC}"
