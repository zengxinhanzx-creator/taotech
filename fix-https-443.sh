#!/bin/bash

# 修复 HTTPS 443 端口连接被拒绝问题

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
echo -e "${BLUE}修复 HTTPS 443 端口连接问题${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查权限
if [ "$EUID" -ne 0 ]; then 
    SUDO="sudo"
else
    SUDO=""
fi

# 1. 检查 SSL 证书
echo -e "${BLUE}[1/5]${NC} 检查 SSL 证书..."
CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ]; then
    echo -e "${GREEN}✓${NC} SSL 证书存在"
    SSL_CERT="$CERT_PATH"
    SSL_KEY="$KEY_PATH"
else
    echo -e "${RED}❌${NC} SSL 证书不存在"
    echo "  正在获取证书..."
    
    # 检查 Certbot
    if ! command -v certbot &> /dev/null; then
        echo "安装 Certbot..."
        if [ -f /etc/debian_version ]; then
            $SUDO apt update
            $SUDO apt install -y certbot
        elif [ -f /etc/redhat-release ]; then
            $SUDO yum install -y certbot
        fi
    fi
    
    # 临时停止 Nginx
    $SUDO systemctl stop nginx 2>/dev/null || true
    sleep 2
    
    # 获取证书
    $SUDO certbot certonly --standalone -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN" 2>/dev/null || {
        echo "使用交互模式获取证书..."
        $SUDO certbot certonly --standalone -d "$DOMAIN" -d "www.$DOMAIN"
    }
    
    # 重启 Nginx
    $SUDO systemctl start nginx 2>/dev/null || true
    
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        SSL_CERT="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
        SSL_KEY="/etc/letsencrypt/live/$DOMAIN/privkey.pem"
        echo -e "${GREEN}✓${NC} 证书获取成功"
    else
        echo -e "${RED}❌${NC} 证书获取失败，请手动运行: sudo ./setup-https.sh"
        exit 1
    fi
fi
echo ""

# 2. 更新 Nginx 配置
echo -e "${BLUE}[2/5]${NC} 更新 Nginx 配置..."
$SUDO mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled 2>/dev/null || true

# 创建完整的 HTTPS 配置
$SUDO tee "$NGINX_CONFIG" > /dev/null << NGINX_EOF
# HTTP 重定向到 HTTPS
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN _;
    return 301 https://\$host\$request_uri;
}

# HTTPS 服务器
server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN _;
    
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

echo -e "${GREEN}✓${NC} Nginx 配置已更新"
echo ""

# 3. 启用配置
echo -e "${BLUE}[3/5]${NC} 启用 Nginx 配置..."
$SUDO ln -sf "$NGINX_CONFIG" "$NGINX_ENABLED"
echo -e "${GREEN}✓${NC} 配置已启用"
echo ""

# 4. 测试配置
echo -e "${BLUE}[4/5]${NC} 测试 Nginx 配置..."
if $SUDO nginx -t 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Nginx 配置测试通过"
else
    echo -e "${RED}❌${NC} Nginx 配置测试失败"
    $SUDO nginx -t
    exit 1
fi
echo ""

# 5. 重启 Nginx
echo -e "${BLUE}[5/5]${NC} 重启 Nginx..."
$SUDO systemctl restart nginx 2>/dev/null || {
    $SUDO nginx -s reload 2>/dev/null || {
        echo -e "${YELLOW}⚠${NC} Nginx 重启失败，尝试启动..."
        $SUDO systemctl start nginx 2>/dev/null || $SUDO nginx
    }
}

sleep 2

# 检查端口
if $SUDO lsof -i :443 2>/dev/null | grep -q LISTEN; then
    echo -e "${GREEN}✓${NC} 端口 443 正在监听"
else
    echo -e "${RED}❌${NC} 端口 443 未监听"
    echo "检查 Nginx 状态..."
    $SUDO systemctl status nginx --no-pager -l || true
fi
echo ""

# 检查防火墙
echo -e "${BLUE}检查防火墙...${NC}"
if command -v ufw &> /dev/null; then
    if ! $SUDO ufw status | grep -q "443/tcp"; then
        echo "开放端口 443..."
        $SUDO ufw allow 443/tcp
        $SUDO ufw reload
    fi
fi

if command -v firewall-cmd &> /dev/null; then
    if ! $SUDO firewall-cmd --list-ports 2>/dev/null | grep -q "443/tcp"; then
        $SUDO firewall-cmd --permanent --add-port=443/tcp
        $SUDO firewall-cmd --reload
    fi
fi
echo ""

# 完成
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ 修复完成${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "测试 HTTPS 连接:"
echo "  curl -I https://$DOMAIN"
echo "  或"
echo "  curl https://$DOMAIN"
echo ""
echo "如果仍然无法连接，请检查:"
echo "  1. 云服务器安全组是否开放 443 端口"
echo "  2. DNS 解析是否正确: nslookup $DOMAIN"
echo "  3. Nginx 错误日志: sudo tail -f /var/log/nginx/error.log"
echo ""

