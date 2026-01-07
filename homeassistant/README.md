# Home Assistant Docker Setup

## Pre-requisite

VM running Debian 13. The VM need to be run as an actual VM, not LXC in Proxmox.
Otherwise, the USB passthrough will not work correctly.

## Quick Setup (Automated)

Run the automated setup script to install all prerequisites and deploy Home Assistant:

```bash
./setup.sh
```

The script will:
1. Add your user to the `dialout` group (for serial device access)
2. Install Docker and Docker Compose (if not already installed)
3. Add your user to the `docker` group (to run docker without sudo)
4. Deploy Home Assistant with `docker compose up -d`

**Note:** If group memberships are added, you'll need to log out and log back in for changes to take effect.

## Manual Setup

If you prefer to run the steps manually:

### Prerequisites

### 1. Add User to dialout Group

The user needs to be in the `dialout` group to access serial devices (required for Zigbee/Z-Wave USB adapters):

```bash
sudo usermod -aG dialout $USER
```

After running this command, **log out and log back in** for the group change to take effect.

Verify membership:
```bash
groups
```

### 2. Install Docker

Install Docker and Docker Compose:

```bash
# Update package index
sudo apt update

# Add Docker's official GPG key:
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Install Docker Compose (if not included)
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group (optional, to run docker without sudo)
sudo usermod -aG docker $USER
```

Log out and back in for group changes to take effect.

## Deployment

Run Home Assistant in detached mode:

```bash
sudo docker compose up -d
```

## Access

Home Assistant will be available at:
- http://localhost:8123
- http://<host-ip>:8123

## Management Commands

```bash
# View logs
sudo docker compose logs -f

# Stop containers
sudo docker compose down

# Restart containers
sudo docker compose restart

# Pull latest images and restart
sudo docker compose pull
sudo docker compose up -d
```
