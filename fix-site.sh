#!/bin/bash

# 网站访问修复脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="taotech.com.hk"
APP_NAME="taotech"
NGINX_CONFIG="/etc/nginx/sites-available/${APP_NAME}"
NGINX_ENABLED="/etc/nginx/sites-enabled/${APP_NAME}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}网站访问修复脚本${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查权限
if [ "$EUID" -ne 0 ]; then 
    SUDO="sudo"
else
    SUDO=""
fi

# 1. 检查 SSL 证书
echo -e "${BLUE}[1/4]${NC} 检查 SSL 证书..."
SSL_CERT="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
SSL_KEY="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
    echo -e "${RED}❌ SSL 证书不存在${NC}"
    echo -e "${YELLOW}提示: 运行 ./setup-https.sh 获取证书${NC}"
    echo ""
    echo "继续配置 HTTP 到 HTTPS 重定向（需要先有证书）..."
    HAS_CERT=false
else
    echo -e "${GREEN}✓${NC} SSL 证书存在"
    HAS_CERT=true
fi
echo ""

# 2. 更新 Nginx 配置
echo -e "${BLUE}[2/4]${NC} 更新 Nginx 配置..."

# 创建配置目录
$SUDO mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled 2>/dev/null || true

if [ "$HAS_CERT" = true ]; then
    # 有证书：配置 HTTP 重定向和 HTTPS
    echo "创建包含 HTTP 重定向和 HTTPS 的配置..."
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
    echo -e "${GREEN}✓${NC} Nginx 配置已更新（HTTP 重定向 + HTTPS）"
else
    # 无证书：只配置 HTTP
    echo "创建仅 HTTP 的配置..."
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
    echo -e "${GREEN}✓${NC} Nginx 配置已更新（仅 HTTP）"
    echo -e "${YELLOW}提示: 获取 SSL 证书后，运行 ./start.sh 自动配置 HTTPS${NC}"
fi

# 启用配置
if [ ! -L "$NGINX_ENABLED" ]; then
    $SUDO ln -sf "$NGINX_CONFIG" "$NGINX_ENABLED"
    echo -e "${GREEN}✓${NC} Nginx 配置已启用"
fi
echo ""

# 3. 测试并重载 Nginx
echo -e "${BLUE}[3/4]${NC} 测试并重载 Nginx..."
if command -v nginx &> /dev/null; then
    if $SUDO nginx -t 2>/dev/null; then
        $SUDO systemctl reload nginx 2>/dev/null || $SUDO nginx -s reload 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Nginx 配置已重载"
    else
        echo -e "${RED}❌ Nginx 配置测试失败${NC}"
        $SUDO nginx -t
        exit 1
    fi
else
    echo -e "${YELLOW}⚠${NC} Nginx 未安装"
fi
echo ""

# 4. 开放防火墙端口
echo -e "${BLUE}[4/4]${NC} 检查并开放防火墙端口..."

# 开放 80 端口
if command -v firewall-cmd &> /dev/null; then
    if ! $SUDO firewall-cmd --list-ports 2>/dev/null | grep -q "80/tcp"; then
        echo "开放 80 端口..."
        $SUDO firewall-cmd --permanent --add-port=80/tcp 2>/dev/null || true
        $SUDO firewall-cmd --reload 2>/dev/null || true
        echo -e "${GREEN}✓${NC} 防火墙已开放 80 端口"
    else
        echo -e "${GREEN}✓${NC} 防火墙已开放 80 端口"
    fi
    
    if [ "$HAS_CERT" = true ]; then
        if ! $SUDO firewall-cmd --list-ports 2>/dev/null | grep -q "443/tcp"; then
            echo "开放 443 端口..."
            $SUDO firewall-cmd --permanent --add-port=443/tcp 2>/dev/null || true
            $SUDO firewall-cmd --reload 2>/dev/null || true
            echo -e "${GREEN}✓${NC} 防火墙已开放 443 端口"
        else
            echo -e "${GREEN}✓${NC} 防火墙已开放 443 端口"
        fi
    fi
elif command -v ufw &> /dev/null; then
    if ! $SUDO ufw status 2>/dev/null | grep -q "80/tcp"; then
        echo "开放 80 端口..."
        $SUDO ufw allow 80/tcp 2>/dev/null || true
        echo -e "${GREEN}✓${NC} UFW 已开放 80 端口"
    else
        echo -e "${GREEN}✓${NC} UFW 已开放 80 端口"
    fi
    
    if [ "$HAS_CERT" = true ]; then
        if ! $SUDO ufw status 2>/dev/null | grep -q "443/tcp"; then
            echo "开放 443 端口..."
            $SUDO ufw allow 443/tcp 2>/dev/null || true
            echo -e "${GREEN}✓${NC} UFW 已开放 443 端口"
        else
            echo -e "${GREEN}✓${NC} UFW 已开放 443 端口"
        fi
    fi
else
    echo -e "${YELLOW}⚠${NC} 未检测到防火墙工具"
    echo -e "${YELLOW}提示: 如果是云服务器，请在控制台配置安全组，开放 80 和 443 端口${NC}"
fi
echo ""

# 完成
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ 修复完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 验证
echo -e "${BLUE}验证访问:${NC}"
sleep 2

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -L http://$DOMAIN 2>&1 || echo "000")
if [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
    echo -e "${GREEN}✓${NC} HTTP 正确重定向到 HTTPS (状态码: $HTTP_STATUS)"
elif [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${YELLOW}⚠${NC} HTTP 返回 200（如果已配置证书，应该重定向）"
else
    echo -e "${YELLOW}⚠${NC} HTTP 状态码: $HTTP_STATUS"
fi

if [ "$HAS_CERT" = true ]; then
    HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -k https://$DOMAIN 2>&1 || echo "000")
    if [ "$HTTPS_STATUS" = "200" ]; then
        echo -e "${GREEN}✓${NC} HTTPS 访问正常 (状态码: $HTTPS_STATUS)"
    else
        echo -e "${YELLOW}⚠${NC} HTTPS 状态码: $HTTPS_STATUS"
        echo -e "  ${YELLOW}提示: 如果无法访问，请检查:${NC}"
        echo "    1. 云服务器安全组是否开放 443 端口"
        echo "    2. 运行 ./check-site.sh 查看详细诊断"
    fi
else
    echo -e "${YELLOW}⚠${NC} HTTPS 未配置（需要先获取 SSL 证书）"
fi
echo ""

