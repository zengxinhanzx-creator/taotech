#!/bin/bash

# 修复 HTTPS 无法访问问题

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
echo -e "${BLUE}修复 HTTPS 访问问题${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查权限
if [ "$EUID" -ne 0 ]; then 
    SUDO="sudo"
else
    SUDO=""
fi

# 1. 诊断当前状态
echo -e "${BLUE}[1/6]${NC} 诊断当前状态..."
echo ""

# 检查 HTTP 是否正常
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 --max-time 2 | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✓${NC} HTTP (80) 正常"
else
    echo -e "${RED}❌${NC} HTTP (80) 异常"
fi

# 检查 HTTPS 端口
HTTPS_PORT=$(grep -oP 'listen \K[0-9]+.*ssl' "$NGINX_CONFIG" 2>/dev/null | grep -oP '^[0-9]+' | head -1)
HTTPS_PORT=${HTTPS_PORT:-8443}

if [ -z "$HTTPS_PORT" ]; then
    echo -e "${RED}❌${NC} 未找到 HTTPS 端口配置"
    HTTPS_PORT=8443
    echo "使用默认端口: $HTTPS_PORT"
else
    echo -e "${GREEN}✓${NC} HTTPS 端口: $HTTPS_PORT"
fi

# 检查端口监听
if $SUDO lsof -i :$HTTPS_PORT 2>/dev/null | grep -q LISTEN; then
    echo -e "${GREEN}✓${NC} 端口 $HTTPS_PORT 正在监听"
else
    echo -e "${RED}❌${NC} 端口 $HTTPS_PORT 未监听"
fi
echo ""

# 2. 检查 SSL 证书
echo -e "${BLUE}[2/6]${NC} 检查 SSL 证书..."
CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ]; then
    echo -e "${GREEN}✓${NC} SSL 证书存在"
    SSL_CERT="$CERT_PATH"
    SSL_KEY="$KEY_PATH"
    
    # 检查证书有效性
    CERT_EXPIRY=$(openssl x509 -enddate -noout -in "$CERT_PATH" 2>/dev/null | cut -d= -f2)
    echo "  证书有效期至: $CERT_EXPIRY"
else
    echo -e "${RED}❌${NC} SSL 证书不存在"
    echo "  正在获取证书..."
    
    # 安装 Certbot
    if ! command -v certbot &> /dev/null; then
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
        echo "使用交互模式..."
        $SUDO certbot certonly --standalone -d "$DOMAIN" -d "www.$DOMAIN"
    }
    
    # 重启 Nginx
    $SUDO systemctl start nginx 2>/dev/null || true
    
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        SSL_CERT="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
        SSL_KEY="/etc/letsencrypt/live/$DOMAIN/privkey.pem"
        echo -e "${GREEN}✓${NC} 证书获取成功"
    else
        echo -e "${RED}❌${NC} 证书获取失败"
        exit 1
    fi
fi
echo ""

# 3. 检查 Nginx 配置
echo -e "${BLUE}[3/6]${NC} 检查 Nginx 配置..."
if [ ! -f "$NGINX_CONFIG" ]; then
    echo -e "${RED}❌${NC} Nginx 配置文件不存在"
    $SUDO mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled 2>/dev/null || true
fi

# 检查配置中是否有 HTTPS
if [ -f "$NGINX_CONFIG" ] && grep -q "listen.*ssl" "$NGINX_CONFIG"; then
    echo -e "${GREEN}✓${NC} Nginx 配置包含 HTTPS"
    CURRENT_PORT=$(grep -oP 'listen \K[0-9]+.*ssl' "$NGINX_CONFIG" 2>/dev/null | grep -oP '^[0-9]+' | head -1)
    if [ ! -z "$CURRENT_PORT" ]; then
        HTTPS_PORT=$CURRENT_PORT
        echo "  当前 HTTPS 端口: $HTTPS_PORT"
    fi
else
    echo -e "${YELLOW}⚠${NC} Nginx 配置缺少 HTTPS"
fi
echo ""

# 4. 更新 Nginx 配置
echo -e "${BLUE}[4/6]${NC} 更新 Nginx 配置..."
$SUDO mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled 2>/dev/null || true

# 创建完整的配置（HTTP + HTTPS）
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

# HTTPS 服务器
server {
    listen $HTTPS_PORT ssl http2;
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

# 5. 启用配置并测试
echo -e "${BLUE}[5/6]${NC} 启用配置..."
$SUDO ln -sf "$NGINX_CONFIG" "$NGINX_ENABLED"

if $SUDO nginx -t 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Nginx 配置测试通过"
else
    echo -e "${RED}❌${NC} Nginx 配置测试失败"
    $SUDO nginx -t
    exit 1
fi
echo ""

# 6. 重启 Nginx
echo -e "${BLUE}[6/6]${NC} 重启 Nginx..."
$SUDO systemctl restart nginx 2>/dev/null || {
    $SUDO nginx -s reload 2>/dev/null || {
        echo "尝试启动 Nginx..."
        $SUDO systemctl start nginx 2>/dev/null || $SUDO nginx
    }
}

sleep 3

# 验证
echo ""
echo -e "${BLUE}验证服务状态...${NC}"

# 检查端口
if $SUDO lsof -i :$HTTPS_PORT 2>/dev/null | grep -q LISTEN; then
    echo -e "${GREEN}✓${NC} 端口 $HTTPS_PORT 正在监听"
else
    echo -e "${RED}❌${NC} 端口 $HTTPS_PORT 未监听"
    echo "检查 Nginx 状态..."
    $SUDO systemctl status nginx --no-pager -l | head -20 || true
fi

# 测试本地连接
if curl -s -k -o /dev/null -w "%{http_code}" https://localhost:$HTTPS_PORT --max-time 3 > /dev/null 2>&1; then
    HTTP_CODE=$(curl -s -k -o /dev/null -w "%{http_code}" https://localhost:$HTTPS_PORT --max-time 3)
    echo -e "${GREEN}✓${NC} 本地 HTTPS 连接成功 (HTTP $HTTP_CODE)"
else
    echo -e "${RED}❌${NC} 本地 HTTPS 连接失败"
fi

# 开放防火墙
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
echo -e "${GREEN}✓ 修复完成${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}访问地址:${NC}"
echo "  HTTP:  ${GREEN}http://$DOMAIN${NC}"
echo "  HTTPS: ${GREEN}https://$DOMAIN:$HTTPS_PORT${NC}"
echo ""
echo -e "${BLUE}测试命令:${NC}"
echo "  curl -k https://$DOMAIN:$HTTPS_PORT"
echo "  curl -I https://$DOMAIN:$HTTPS_PORT"
echo ""
echo -e "${YELLOW}如果仍然无法访问，请检查:${NC}"
echo "  1. 云服务器安全组是否开放端口 $HTTPS_PORT"
echo "  2. DNS 解析是否正确: nslookup $DOMAIN"
echo "  3. Nginx 错误日志: sudo tail -f /var/log/nginx/error.log"
echo ""

