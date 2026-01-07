#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================"
echo "Home Assistant Docker Setup Script"
echo "======================================"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}ERROR: Do not run this script as root or with sudo${NC}"
    echo "The script will prompt for sudo when needed."
    exit 1
fi

# Function to check if user is in a group
user_in_group() {
    groups "$USER" | grep -q "\b$1\b"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Add user to dialout group
echo -e "${YELLOW}[1/4] Checking dialout group membership...${NC}"
if user_in_group "dialout"; then
    echo -e "${GREEN}✓ User $USER is already in dialout group${NC}"
    DIALOUT_ADDED=false
else
    echo "Adding $USER to dialout group..."
    sudo usermod -aG dialout "$USER"
    echo -e "${GREEN}✓ User added to dialout group${NC}"
    DIALOUT_ADDED=true
fi
echo ""

# Step 2: Check and install Docker
echo -e "${YELLOW}[2/4] Checking Docker installation...${NC}"
if command_exists docker; then
    echo -e "${GREEN}✓ Docker is already installed${NC}"
    docker --version
    DOCKER_INSTALLED=false
else
    echo "Docker not found. Installing Docker..."

    # Add Docker's official GPG key:
    echo "Adding Docker GPG key..."
    sudo apt update
    sudo apt install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo "Setting up Docker repository..."
    sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    echo "Installing Docker..."
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo -e "${GREEN}✓ Docker installed successfully${NC}"
    docker --version
    DOCKER_INSTALLED=true
fi
echo ""

# Step 3: Add user to docker group
echo -e "${YELLOW}[3/4] Checking docker group membership...${NC}"
if user_in_group "docker"; then
    echo -e "${GREEN}✓ User $USER is already in docker group${NC}"
    DOCKER_GROUP_ADDED=false
else
    echo "Adding $USER to docker group..."
    sudo usermod -aG docker "$USER"
    echo -e "${GREEN}✓ User added to docker group${NC}"
    DOCKER_GROUP_ADDED=true
fi
echo ""

# Step 4: Deploy Home Assistant
echo -e "${YELLOW}[4/4] Deploying Home Assistant...${NC}"

# Check if docker-compose.yml exists
if [ ! -f "$SCRIPT_DIR/docker-compose.yml" ]; then
    echo -e "${RED}ERROR: docker-compose.yml not found in $SCRIPT_DIR${NC}"
    exit 1
fi

cd "$SCRIPT_DIR"

# Check if we need to use newgrp or if groups are already active
if [ "$DIALOUT_ADDED" = true ] || [ "$DOCKER_GROUP_ADDED" = true ]; then
    echo -e "${YELLOW}Note: Group changes detected. Running with sudo for this session.${NC}"
    echo "Starting Home Assistant containers..."
    sudo docker compose up -d
else
    echo "Starting Home Assistant containers..."
    docker compose up -d
fi

echo -e "${GREEN}✓ Home Assistant deployed successfully${NC}"
echo ""

# Final status and next steps
echo "======================================"
echo -e "${GREEN}Setup Complete!${NC}"
echo "======================================"
echo ""

if [ "$DIALOUT_ADDED" = true ] || [ "$DOCKER_GROUP_ADDED" = true ]; then
    echo -e "${YELLOW}⚠ IMPORTANT: Group changes require logout/login${NC}"
    echo ""
    echo "The following group memberships were added:"
    [ "$DIALOUT_ADDED" = true ] && echo "  • dialout (for serial device access)"
    [ "$DOCKER_GROUP_ADDED" = true ] && echo "  • docker (to run docker without sudo)"
    echo ""
    echo -e "${YELLOW}Please log out and log back in for changes to take effect.${NC}"
    echo "After logging back in, you can run docker commands without sudo."
    echo ""
fi

echo "Home Assistant is now running!"
echo ""
echo "Access Home Assistant at:"
echo "  • http://localhost:8123"
echo "  • http://$(hostname -I | awk '{print $1}'):8123"
echo ""
echo "Useful commands:"
echo "  • View logs:        docker compose logs -f"
echo "  • Stop:             docker compose down"
echo "  • Restart:          docker compose restart"
echo "  • Update & restart: docker compose pull && docker compose up -d"
echo ""
echo "Check status:"
docker compose ps
echo ""
