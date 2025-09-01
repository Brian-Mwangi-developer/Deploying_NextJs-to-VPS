# Next.js Self-Hosting Deployment Guide

This repository provides automated deployment scripts for self-hosting Next.js applications with two deployment options: with or without a custom domain.

## =� What's Included

- **nextjs-app/**: Contains the deployment script for general Next.js applications
- **Optimized Performance**: Uses swap files to reduce memory usage and Next.js standalone builds (up to 80% smaller)
- **Docker Integration**: Automated containerization with Docker Compose
- **Nginx Reverse Proxy**: Production-ready web server configuration

## =� Quick Start

### Prerequisites

- A VPS/Server (tested on Ubuntu/Debian)
- SSH access to your server
- Git repository with your Next.js application

### Step 1: Connect to Your Server

For **Digital Ocean** droplets:
```bash
ssh root@your-server-ip
```

For other VPS providers with key-based authentication:
```bash
ssh -i /path/to/your-private-key user@your-server-ip
```

### Step 2: Upload Deployment Script

From your local machine, copy the deployment script to your server:

```bash
# Navigate to the nextjs-app directory
cd nextjs-app

# Copy the deployment script to your server root directory
scp deploy.sh root@your-server-ip:~/
```

### Step 3: Configure the Script

SSH into your server and edit the deployment script:

```bash
ssh root@your-server-ip
nano ~/deploy.sh
```

Update the following variables at the top of the script:

```bash
DATABASE_URL="your-database-connection-string"
GITHUB_TOKEN="your-github-token-if-private-repo"
REPO_URL="https://${GITHUB_TOKEN}@github.com/yourusername/your-repo-name.git"
```

## < Deployment Options

### Option 1: Deploy WITHOUT Custom Domain

This option uses your server's IP address directly.

1. In the `deploy.sh` script, ensure:
   ```bash
   USE_SSL=false
   ```

2. Run the deployment:
   ```bash
   chmod +x ~/deploy.sh
   ./deploy.sh
   ```

3. Your application will be available at: `http://your-server-ip`

### Option 2: Deploy WITH Custom Domain

This option allows you to use your own domain with SSL/HTTPS.

1. **Point your domain to your server**:
   - Add an A record pointing `yourdomain.com` to your server's IP
   - Add an A record pointing `www.yourdomain.com` to your server's IP

2. **Modify the script** to enable SSL:
   ```bash
   USE_SSL=true
   DOMAIN="yourdomain.com"  # Add this line
   ```

3. **Update Nginx configuration** in the script (around line 129) to include SSL setup:
   ```bash
   # You'll need to add SSL certificate configuration
   # Consider using Let's Encrypt for free SSL certificates
   ```

4. Run the deployment:
   ```bash
   chmod +x ~/deploy.sh
   ./deploy.sh
   ```

## =' What the Script Does

1. **System Updates**: Updates Ubuntu/Debian packages
2. **Swap File Creation**: Adds 1GB swap to reduce memory pressure
3. **Docker Installation**: Installs Docker and Docker Compose
4. **Repository Clone**: Downloads your Next.js application
5. **Environment Setup**: Creates production environment file
6. **Docker Build**: Creates optimized Docker image
7. **Nginx Configuration**: Sets up reverse proxy with rate limiting
8. **Application Start**: Launches your app in production mode

## =� Performance Optimizations

- **Swap File**: 1GB swap file reduces memory requirements
- **Standalone Build**: Next.js standalone output reduces image size by up to 80%
- **Docker Multi-stage**: Optimized Docker builds
- **Nginx Caching**: Efficient static asset serving
- **Rate Limiting**: Built-in DDoS protection

## =� Troubleshooting

### Check Application Status
```bash
cd ~/myapp
sudo docker-compose ps
sudo docker-compose logs
```

### Restart Services
```bash
sudo docker-compose restart
sudo systemctl restart nginx
```

### View Nginx Logs
```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## =� Environment Variables

The script creates a `.env` file with:
```
DATABASE_URL=your-database-url
NODE_ENV=production
```

Add additional environment variables as needed for your application.

## = Security Considerations

- The script automatically removes GitHub tokens from git configuration
- Nginx includes rate limiting (10 requests/second)
- Docker containers run with restart policies
- Consider setting up UFW firewall for additional security

## > Credits

This deployment setup is derived from the excellent work by **@leerob**:
- Original repository: https://github.com/leerob/next-self-host
- Enhanced with additional optimizations and deployment options

## =� Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review Docker and Nginx logs
3. Ensure all prerequisites are met
4. Verify your repository structure includes a proper Dockerfile

---

**Note**: This setup is optimized for production deployments on Ubuntu/Debian systems with Digital Ocean, but should work on most VPS providers.

Author:
### Brian Mwangi