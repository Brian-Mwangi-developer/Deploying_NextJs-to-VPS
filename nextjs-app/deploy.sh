#!/bin/bash
DATABASE_URL="your database url"
GITHUB_TOKEN="Create a github access token under developer setting if private Repo"


USE_SSL=false

# Script Vars
REPO_URL="https://${GITHUB_TOKEN}@github.com/github_username/your_repo_name.git"
APP_DIR=~/myapp
SWAP_SIZE="1G"

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Add Swap Space
echo "Adding swap space..."
sudo fallocate -l $SWAP_SIZE /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make swap permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Install Docker
echo "Installing Docker..."
sudo apt update
sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release -y

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y


echo "Installing Docker Compose..."
sudo rm -f /usr/local/bin/docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

if [ ! -f /usr/local/bin/docker-compose ]; then
  echo "Docker Compose download failed. Exiting."
  exit 1
fi

sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify installation
docker-compose --version
if [ $? -ne 0 ]; then
  echo "Docker Compose installation failed. Exiting."
  exit 1
fi

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add current user to docker group (optional - requires re-login)
sudo usermod -aG docker $USER

# Clone/Update repository
if [ -d "$APP_DIR" ]; then
  echo "Directory $APP_DIR exists. Pulling latest changes..."
  cd $APP_DIR && git pull
else
  echo "Cloning private repository..."
  git clone $REPO_URL $APP_DIR
  cd $APP_DIR
fi


echo "Creating environment file..."
cat > "$APP_DIR/.env" <<EOL
DATABASE_URL=$DATABASE_URL
NODE_ENV=production
EOL


# Create docker-compose.yml for single service
echo "Creating docker-compose.yml..."
cat > "$APP_DIR/docker-compose.yml" <<EOL
version: '3.8'

services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=\${DATABASE_URL}
      - NODE_ENV=production
    restart: unless-stopped
EOL



# Install Nginx
echo "Installing and configuring Nginx..."
sudo apt install nginx -y

# Remove existing config
sudo rm -f /etc/nginx/sites-available/myapp
sudo rm -f /etc/nginx/sites-enabled/myapp

# Get server IP address
SERVER_IP=$(curl -s ifconfig.me)
echo "Server IP: $SERVER_IP"


# Configure Nginx based on SSL preference
if [ "$USE_SSL" = true ]; then
  echo "SSL is enabled but no domain provided. Skipping SSL setup."
  echo "To use SSL, you need a domain name pointing to this server."
  USE_SSL=false
fi

# Create Nginx configuration for HTTP only
sudo cat > /etc/nginx/sites-available/myapp <<EOL
limit_req_zone \$binary_remote_addr zone=mylimit:10m rate=10r/s;

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name _;

    # Rate limiting
    limit_req zone=mylimit burst=20 nodelay;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;

        # Disable buffering for streaming
        proxy_buffering off;
        proxy_set_header X-Accel-Buffering no;
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOL

 Enable site
sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/myapp

# Remove default Nginx site
sudo rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
sudo nginx -t
if [ $? -eq 0 ]; then
    sudo systemctl restart nginx
else
    echo "Nginx configuration test failed. Please check the config."
    exit 1
fi

# Build and run containers
echo "Building and starting application..."
cd $APP_DIR

# Use sudo for Docker commands initially
sudo docker-compose down 2>/dev/null || true
sudo docker-compose up --build -d

# Check if containers are running
echo "Checking container status..."
sleep 10
if sudo docker-compose ps | grep -q "Up"; then
    echo "✅ Application started successfully!"
else
    echo "❌ Application failed to start. Checking logs..."
    sudo docker-compose logs
    exit 1
fi

# Cleanup GitHub token from git config (security)
cd $APP_DIR
git remote set-url origin https://github.com/github_username/repo_name.git

echo "
🎉 Deployment Complete!

Your Next.js application is now running at: http://$SERVER_IP