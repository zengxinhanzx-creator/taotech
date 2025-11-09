#!/bin/bash

# TAO Technology 网站一键启动脚本
# 功能：自动配置并启动 PM2 和 Nginx 服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目目录（默认路径）
DEFAULT_DIR="/www/wwwroot/taotech.com.hk"
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 如果当前目录不是默认目录，尝试使用默认目录
if [ "$PROJECT_DIR" != "$DEFAULT_DIR" ] && [ -d "$DEFAULT_DIR" ]; then
    echo -e "${YELLOW}ℹ${NC} 检测到默认目录，切换到: $DEFAULT_DIR"
    PROJECT_DIR="$DEFAULT_DIR"
fi

APP_NAME="taotech"
NGINX_CONFIG="/etc/nginx/sites-available/${APP_NAME}"
NGINX_ENABLED="/etc/nginx/sites-enabled/${APP_NAME}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}TAO Technology 网站一键启动脚本${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查权限
if [ "$EUID" -ne 0 ]; then 
    SUDO="sudo"
else
    SUDO=""
fi

cd "$PROJECT_DIR"

# 1. 检查 Node.js 环境
echo -e "${BLUE}[1/5]${NC} 检查 Node.js 环境..."
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ Node.js 或 npm 未安装${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Node.js: $(node -v) | npm: $(npm -v)"
echo ""

# 2. 安装依赖
echo -e "${BLUE}[2/5]${NC} 检查依赖..."
if [ ! -d "node_modules" ]; then
    npm install
fi
echo -e "${GREEN}✓${NC} 依赖就绪"
echo ""

# 3. 检查并安装 PM2
echo -e "${BLUE}[3/5]${NC} 检查 PM2..."
NPM_GLOBAL_PATH=$(npm config get prefix 2>/dev/null || echo "$HOME/.npm-global")
PM2_PATH="$NPM_GLOBAL_PATH/bin/pm2"

if [ -f "$PM2_PATH" ]; then
    PM2_CMD="$PM2_PATH"
elif command -v pm2 &> /dev/null; then
    PM2_CMD="pm2"
else
    echo "安装 PM2..."
    npm install -g pm2
    NPM_GLOBAL_PATH=$(npm config get prefix 2>/dev/null || echo "$HOME/.npm-global")
    PM2_PATH="$NPM_GLOBAL_PATH/bin/pm2"
    export PATH="$NPM_GLOBAL_PATH/bin:$PATH"
    PM2_CMD=$(command -v pm2 2>/dev/null || echo "$PM2_PATH")
fi
echo -e "${GREEN}✓${NC} PM2: $($PM2_CMD -v 2>/dev/null || echo '已安装')"
echo ""

# 4. 启动 PM2 应用
echo -e "${BLUE}[4/5]${NC} 启动 Node.js 应用..."

# 停止旧进程
if $PM2_CMD list 2>/dev/null | grep -q "$APP_NAME"; then
    $PM2_CMD delete "$APP_NAME" 2>/dev/null || true
    sleep 1
fi

# 启动应用
if [ -f "ecosystem.config.js" ]; then
    $PM2_CMD start ecosystem.config.js --env production
else
    $PM2_CMD start server.js --name "$APP_NAME" --env production
fi

# 保存进程列表
$PM2_CMD save 2>/dev/null || true

# 等待启动
sleep 2

# 验证启动
if $PM2_CMD list 2>/dev/null | grep -q "$APP_NAME.*online"; then
    echo -e "${GREEN}✓${NC} PM2 应用启动成功"
else
    echo -e "${RED}❌ 应用启动失败${NC}"
    $PM2_CMD logs "$APP_NAME" --lines 10 --err
    exit 1
fi
echo ""

# 5. 配置 Nginx
echo -e "${BLUE}[5/5]${NC} 配置 Nginx..."
if command -v nginx &> /dev/null; then
    # 创建配置目录
    $SUDO mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled 2>/dev/null || true
    
    # 检查是否有 SSL 证书
    DOMAIN="taotech.com.hk"
    SSL_CERT=""
    SSL_KEY=""
    
    # 查找证书
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        SSL_CERT="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
        SSL_KEY="/etc/letsencrypt/live/$DOMAIN/privkey.pem"
    else
        # 尝试查找其他证书
        for cert_dir in /etc/letsencrypt/live/*/; do
            if [ -f "${cert_dir}fullchain.pem" ] && [ -f "${cert_dir}privkey.pem" ]; then
                SSL_CERT="${cert_dir}fullchain.pem"
                SSL_KEY="${cert_dir}privkey.pem"
                DOMAIN=$(basename "$cert_dir")
                break
            fi
        done
    fi
    
    # 创建或更新配置文件
    if [ ! -f "$NGINX_CONFIG" ] || [ "nginx.conf.example" -nt "$NGINX_CONFIG" ]; then
        echo "创建/更新 Nginx 配置..."
        
        if [ ! -z "$SSL_CERT" ] && [ -f "$SSL_CERT" ]; then
            # 有 SSL 证书，配置 HTTPS（标准 443 端口）和 HTTP 重定向
            $SUDO tee "$NGINX_CONFIG" > /dev/null << NGINX_EOF
# HTTP 服务器 - 重定向到 HTTPS
server {
    listen 80;
    server_name _;
    
    return 301 https://\$host\$request_uri;
}

# HTTPS 服务器（标准 443 端口）
server {
    listen 443 ssl http2;
    server_name _;
    
    ssl_certificate $SSL_CERT;
    ssl_certificate_key $SSL_KEY;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
NGINX_EOF
            echo -e "${GREEN}✓${NC} HTTPS 配置已创建（标准 443 端口）"
        else
            # 无 SSL 证书，只配置 HTTP
            $SUDO tee "$NGINX_CONFIG" > /dev/null << 'NGINX_EOF'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
NGINX_EOF
            echo -e "${GREEN}✓${NC} HTTP 配置已创建"
            echo -e "${YELLOW}ℹ${NC} 如需 HTTPS，运行: ./setup-https.sh"
        fi
    fi
    
    # 启用配置
    if [ ! -L "$NGINX_ENABLED" ]; then
        $SUDO ln -sf "$NGINX_CONFIG" "$NGINX_ENABLED"
    fi
    
    # 测试并重载
    if $SUDO nginx -t 2>/dev/null; then
        $SUDO systemctl reload nginx 2>/dev/null || $SUDO nginx -s reload 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Nginx 配置已更新并重载"
    else
        echo -e "${YELLOW}⚠${NC} Nginx 配置测试失败"
        $SUDO nginx -t
    fi
else
    echo -e "${YELLOW}⚠${NC} Nginx 未安装，跳过配置"
fi
echo ""

# 完成
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ 启动完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}服务状态:${NC}"
$PM2_CMD list | grep "$APP_NAME" || echo "PM2 应用未运行"
echo ""
echo -e "${BLUE}常用命令:${NC}"
echo "  查看日志: ${GREEN}$PM2_CMD logs $APP_NAME${NC}"
echo "  查看状态: ${GREEN}$PM2_CMD status${NC}"
echo "  重启: ${GREEN}$PM2_CMD restart $APP_NAME${NC}"
echo "  停止: ${GREEN}$PM2_CMD stop $APP_NAME${NC}"
echo ""
echo -e "${BLUE}访问地址:${NC}"
echo "  本地: ${GREEN}http://localhost:8080${NC}"

# 检查 HTTPS
if [ -f "$NGINX_CONFIG" ] && grep -q "listen.*443.*ssl" "$NGINX_CONFIG"; then
    echo "  HTTP: ${GREEN}http://$DOMAIN${NC} (自动重定向到 HTTPS)"
    echo "  HTTPS: ${GREEN}https://$DOMAIN${NC}"
else
    echo "  HTTP: ${GREEN}http://$DOMAIN${NC}"
    echo -e "  ${YELLOW}HTTPS: 未配置（运行 ./setup-https.sh 配置）${NC}"
fi
echo ""
