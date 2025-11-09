#!/bin/bash

# 配置 HTTPS 使用自定义端口（非 443）

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 默认项目目录
DEFAULT_DIR="/www/wwwroot/taotech.com.hk"
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ "$PROJECT_DIR" != "$DEFAULT_DIR" ] && [ -d "$DEFAULT_DIR" ]; then
    PROJECT_DIR="$DEFAULT_DIR"
fi

cd "$PROJECT_DIR"

DOMAIN="taotech.com.hk"
NGINX_CONFIG="/etc/nginx/sites-available/taotech"
NGINX_ENABLED="/etc/nginx/sites-enabled/taotech"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}配置 HTTPS 自定义端口${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查权限
if [ "$EUID" -ne 0 ]; then 
    SUDO="sudo"
else
    SUDO=""
fi

# 获取端口号
read -p "请输入 HTTPS 端口号 (默认 8443): " HTTPS_PORT
HTTPS_PORT=${HTTPS_PORT:-8443}

# 验证端口号
if ! [[ "$HTTPS_PORT" =~ ^[0-9]+$ ]] || [ "$HTTPS_PORT" -lt 1024 ] || [ "$HTTPS_PORT" -gt 65535 ]; then
    echo -e "${RED}❌ 无效的端口号，使用默认 8443${NC}"
    HTTPS_PORT=8443
fi

echo -e "${GREEN}使用端口: $HTTPS_PORT${NC}"
echo ""

# 1. 检查 SSL 证书
echo -e "${BLUE}[1/4]${NC} 检查 SSL 证书..."
CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

if [ ! -f "$CERT_PATH" ] || [ ! -f "$KEY_PATH" ]; then
    echo -e "${RED}❌ SSL 证书不存在${NC}"
    echo "请先运行: sudo ./setup-https.sh"
    exit 1
fi

echo -e "${GREEN}✓${NC} SSL 证书存在"
echo ""

# 2. 更新 Nginx 配置
echo -e "${BLUE}[2/4]${NC} 更新 Nginx 配置..."
$SUDO mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled 2>/dev/null || true

# 创建配置（HTTP 不重定向，HTTPS 使用自定义端口）
$SUDO tee "$NGINX_CONFIG" > /dev/null << NGINX_EOF
# HTTP 服务器
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN _;
    
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

# HTTPS 服务器（自定义端口）
server {
    listen $HTTPS_PORT ssl http2;
    server_name $DOMAIN www.$DOMAIN _;
    
    ssl_certificate $CERT_PATH;
    ssl_certificate_key $KEY_PATH;
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

echo -e "${GREEN}✓${NC} Nginx 配置已更新（HTTPS 端口: $HTTPS_PORT）"
echo ""

# 3. 启用配置
echo -e "${BLUE}[3/4]${NC} 启用配置..."
$SUDO ln -sf "$NGINX_CONFIG" "$NGINX_ENABLED"
echo -e "${GREEN}✓${NC} 配置已启用"
echo ""

# 4. 测试并重启
echo -e "${BLUE}[4/4]${NC} 测试并重启 Nginx..."
if $SUDO nginx -t 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Nginx 配置测试通过"
    $SUDO systemctl restart nginx 2>/dev/null || $SUDO nginx -s reload 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Nginx 已重启"
else
    echo -e "${RED}❌${NC} Nginx 配置测试失败"
    $SUDO nginx -t
    exit 1
fi

# 开放防火墙端口
echo ""
echo -e "${BLUE}配置防火墙...${NC}"
if command -v ufw &> /dev/null; then
    $SUDO ufw allow $HTTPS_PORT/tcp 2>/dev/null || true
    echo -e "${GREEN}✓${NC} UFW 已开放端口 $HTTPS_PORT"
fi

if command -v firewall-cmd &> /dev/null; then
    $SUDO firewall-cmd --permanent --add-port=$HTTPS_PORT/tcp 2>/dev/null || true
    $SUDO firewall-cmd --reload 2>/dev/null || true
    echo -e "${GREEN}✓${NC} firewalld 已开放端口 $HTTPS_PORT"
fi

echo ""

# 完成
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ 配置完成${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}访问地址:${NC}"
echo "  HTTP:  ${GREEN}http://$DOMAIN${NC}"
echo "  HTTPS: ${GREEN}https://$DOMAIN:$HTTPS_PORT${NC}"
echo ""
echo -e "${BLUE}测试连接:${NC}"
echo "  curl -k https://$DOMAIN:$HTTPS_PORT"
echo ""
echo -e "${YELLOW}注意:${NC}"
echo "  1. 浏览器访问需要在 URL 中指定端口: https://$DOMAIN:$HTTPS_PORT"
echo "  2. 确保云服务器安全组开放端口 $HTTPS_PORT"
echo "  3. 如果使用 CDN，需要在 CDN 配置中指定后端端口为 $HTTPS_PORT"
echo ""

