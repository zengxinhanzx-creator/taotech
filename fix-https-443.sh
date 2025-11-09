#!/bin/bash

# HTTPS 443 端口修复脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="taotech.com.hk"
APP_NAME="taotech"

# 检测宝塔面板环境
if [ -d "/www/server/panel" ]; then
    IS_BT_PANEL=true
    NGINX_CONFIG="/www/server/panel/vhost/nginx/${DOMAIN}.conf"
    NGINX_CMD="/www/server/nginx/sbin/nginx"
    BT_CERT_PATH="/www/server/panel/vhost/cert/${DOMAIN}"
else
    IS_BT_PANEL=false
    NGINX_CONFIG="/etc/nginx/sites-available/${APP_NAME}"
    NGINX_ENABLED="/etc/nginx/sites-enabled/${APP_NAME}"
    NGINX_CMD="nginx"
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}HTTPS 443 端口修复脚本${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查权限
if [ "$EUID" -ne 0 ]; then 
    SUDO="sudo"
else
    SUDO=""
fi

# 1. 检查 SSL 证书（优先使用宝塔面板证书，然后是 Let's Encrypt）
echo -e "${BLUE}[1/6]${NC} 检查 SSL 证书..."
SSL_CERT=""
SSL_KEY=""

# 1. 优先查找宝塔面板证书
if [ "$IS_BT_PANEL" = true ] && [ -f "${BT_CERT_PATH}/fullchain.pem" ]; then
    SSL_CERT="${BT_CERT_PATH}/fullchain.pem"
    SSL_KEY="${BT_CERT_PATH}/privkey.pem"
    echo -e "${GREEN}✓${NC} 检测到宝塔面板 SSL 证书"
# 2. 查找 Let's Encrypt 证书
elif [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    SSL_CERT="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    SSL_KEY="/etc/letsencrypt/live/$DOMAIN/privkey.pem"
    echo -e "${GREEN}✓${NC} 检测到 Let's Encrypt SSL 证书"
else
    echo -e "${RED}❌ SSL 证书不存在${NC}"
    echo "  宝塔证书路径: ${BT_CERT_PATH}/fullchain.pem"
    echo "  Let's Encrypt 路径: /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    echo ""
    echo -e "${YELLOW}请先运行以下命令获取证书:${NC}"
    echo "  ./setup-https.sh"
    exit 1
fi

echo -e "${GREEN}✓${NC} SSL 证书存在"
echo "  证书: $SSL_CERT"
echo "  密钥: $SSL_KEY"

# 验证证书权限
CERT_PERM=$(stat -c "%a" "$SSL_CERT" 2>/dev/null || stat -f "%OLp" "$SSL_CERT" 2>/dev/null || echo "unknown")
KEY_PERM=$(stat -c "%a" "$SSL_KEY" 2>/dev/null || stat -f "%OLp" "$SSL_KEY" 2>/dev/null || echo "unknown")
echo "  证书权限: $CERT_PERM"
echo "  密钥权限: $KEY_PERM"
echo ""

# 2. 检查 Nginx 是否安装
echo -e "${BLUE}[2/6]${NC} 检查 Nginx..."
if [ "$IS_BT_PANEL" = true ] && [ -f "$NGINX_CMD" ]; then
    NGINX_VERSION=$($NGINX_CMD -v 2>&1 | grep -oP 'nginx/\K[0-9.]+' || echo "unknown")
    echo -e "${GREEN}✓${NC} Nginx 已安装 (版本: $NGINX_VERSION, 宝塔面板)"
elif command -v nginx &> /dev/null; then
    NGINX_VERSION=$(nginx -v 2>&1 | grep -oP 'nginx/\K[0-9.]+' || echo "unknown")
    echo -e "${GREEN}✓${NC} Nginx 已安装 (版本: $NGINX_VERSION)"
else
    echo -e "${RED}❌ Nginx 未安装${NC}"
    exit 1
fi
echo ""

# 3. 创建/更新 Nginx 配置
echo -e "${BLUE}[3/6]${NC} 更新 Nginx 配置..."

# 创建配置目录
if [ "$IS_BT_PANEL" = false ]; then
    $SUDO mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled 2>/dev/null || true
else
    $SUDO mkdir -p /www/server/panel/vhost/nginx 2>/dev/null || true
fi

# 强制更新配置
echo "创建 HTTPS 配置..."
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

echo -e "${GREEN}✓${NC} Nginx 配置已更新"
echo ""

# 4. 启用配置（仅非宝塔面板需要）
echo -e "${BLUE}[4/6]${NC} 启用 Nginx 配置..."
if [ "$IS_BT_PANEL" = false ]; then
    if [ ! -L "$NGINX_ENABLED" ]; then
        $SUDO ln -sf "$NGINX_CONFIG" "$NGINX_ENABLED"
        echo -e "${GREEN}✓${NC} 配置已启用"
    else
        # 强制更新符号链接
        $SUDO rm -f "$NGINX_ENABLED"
        $SUDO ln -sf "$NGINX_CONFIG" "$NGINX_ENABLED"
        echo -e "${GREEN}✓${NC} 配置已更新"
    fi
else
    echo -e "${GREEN}✓${NC} 宝塔面板配置已就绪"
fi
echo ""

# 5. 测试并重启 Nginx
echo -e "${BLUE}[5/6]${NC} 测试并重启 Nginx..."

# 测试配置
if $SUDO $NGINX_CMD -t 2>&1; then
    echo -e "${GREEN}✓${NC} Nginx 配置测试通过"
    
    # 检查 Nginx 是否运行
    if $SUDO systemctl is-active --quiet nginx 2>/dev/null || pgrep -x nginx > /dev/null 2>&1; then
        echo "重启 Nginx..."
        if [ "$IS_BT_PANEL" = true ]; then
            $SUDO $NGINX_CMD -s reload 2>/dev/null || $SUDO systemctl reload nginx 2>/dev/null || {
                $SUDO systemctl restart nginx 2>/dev/null || $SUDO $NGINX_CMD -s reload 2>/dev/null || true
            }
        else
            $SUDO systemctl restart nginx 2>/dev/null || $SUDO nginx -s reload 2>/dev/null || {
                echo "尝试停止并重新启动 Nginx..."
                $SUDO systemctl stop nginx 2>/dev/null || $SUDO nginx -s stop 2>/dev/null || true
                sleep 1
                $SUDO systemctl start nginx 2>/dev/null || $SUDO nginx 2>/dev/null || true
            }
        fi
        sleep 2
        echo -e "${GREEN}✓${NC} Nginx 已重启"
    else
        echo "启动 Nginx..."
        if [ "$IS_BT_PANEL" = true ]; then
            $SUDO systemctl start nginx 2>/dev/null || $SUDO $NGINX_CMD 2>/dev/null || true
        else
            $SUDO systemctl start nginx 2>/dev/null || $SUDO nginx 2>/dev/null || true
        fi
        sleep 2
        echo -e "${GREEN}✓${NC} Nginx 已启动"
    fi
    else
        echo -e "${RED}❌ Nginx 配置测试失败${NC}"
        $SUDO $NGINX_CMD -t
        exit 1
    fi
echo ""

# 6. 检查端口监听和防火墙
echo -e "${BLUE}[6/6]${NC} 检查端口监听和防火墙..."

# 检查端口监听
sleep 2
if command -v ss &> /dev/null; then
    PORT_443=$(ss -tlnp 2>/dev/null | grep ':443 ' || echo "")
elif command -v netstat &> /dev/null; then
    PORT_443=$(netstat -tlnp 2>/dev/null | grep ':443 ' || echo "")
else
    PORT_443=""
fi

if [ ! -z "$PORT_443" ]; then
    echo -e "${GREEN}✓${NC} 端口 443 正在监听"
    echo "  $PORT_443"
else
    echo -e "${RED}❌ 端口 443 未监听${NC}"
    echo ""
    echo "检查 Nginx 错误日志..."
    if [ -f "/var/log/nginx/error.log" ]; then
        $SUDO tail -20 /var/log/nginx/error.log 2>/dev/null || echo "无法读取错误日志"
    fi
    echo ""
    echo -e "${YELLOW}可能的原因:${NC}"
    echo "  1. Nginx 启动失败"
    echo "  2. 443 端口被其他程序占用"
    echo "  3. SSL 证书配置错误"
fi
echo ""

# 开放防火墙端口
echo "检查防火墙..."
if command -v firewall-cmd &> /dev/null; then
    if ! $SUDO firewall-cmd --list-ports 2>/dev/null | grep -q "443/tcp"; then
        echo "开放 443 端口..."
        $SUDO firewall-cmd --permanent --add-port=443/tcp 2>/dev/null || true
        $SUDO firewall-cmd --reload 2>/dev/null || true
        echo -e "${GREEN}✓${NC} 防火墙已开放 443 端口"
    else
        echo -e "${GREEN}✓${NC} 防火墙已开放 443 端口"
    fi
elif command -v ufw &> /dev/null; then
    if ! $SUDO ufw status 2>/dev/null | grep -q "443/tcp"; then
        echo "开放 443 端口..."
        $SUDO ufw allow 443/tcp 2>/dev/null || true
        echo -e "${GREEN}✓${NC} UFW 已开放 443 端口"
    else
        echo -e "${GREEN}✓${NC} UFW 已开放 443 端口"
    fi
else
    echo -e "${YELLOW}⚠${NC} 未检测到防火墙工具"
    echo -e "${YELLOW}提示: 如果是云服务器，请在控制台配置安全组，开放 443 端口${NC}"
fi
echo ""

# 完成并验证
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ 修复完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 验证访问
echo -e "${BLUE}验证 HTTPS 访问:${NC}"
sleep 3

HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 -k https://$DOMAIN 2>&1 || echo "000")
if [ "$HTTPS_STATUS" = "200" ]; then
    echo -e "${GREEN}✓${NC} HTTPS 访问正常 (状态码: $HTTPS_STATUS)"
    echo ""
    echo -e "${GREEN}✓${NC} 网站已成功配置 HTTPS！"
    echo "  访问地址: ${GREEN}https://$DOMAIN${NC}"
elif [ "$HTTPS_STATUS" = "000" ]; then
    echo -e "${RED}❌ HTTPS 连接失败 (状态码: $HTTPS_STATUS)${NC}"
    echo ""
    echo -e "${YELLOW}可能的原因和解决方案:${NC}"
    echo ""
    echo "1. 检查云服务器安全组:"
    echo "   - 登录云服务器控制台"
    echo "   - 找到安全组设置"
    echo "   - 确保入站规则允许 443 端口 (TCP)"
    echo ""
    echo "2. 检查端口占用:"
    echo "   sudo lsof -i :443"
    echo "   sudo netstat -tlnp | grep 443"
    echo ""
    echo "3. 检查 Nginx 状态:"
    echo "   sudo systemctl status nginx"
    echo "   sudo nginx -t"
    echo ""
    echo "4. 查看 Nginx 错误日志:"
    echo "   sudo tail -50 /var/log/nginx/error.log"
    echo ""
    echo "5. 手动测试本地 HTTPS:"
    echo "   curl -k https://localhost"
    echo ""
else
    echo -e "${YELLOW}⚠${NC} HTTPS 状态码: $HTTPS_STATUS"
    echo "  可能需要进一步检查配置"
fi
echo ""

