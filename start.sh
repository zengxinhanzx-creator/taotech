#!/bin/bash

# TAO Technology 网站一键启动脚本
# 功能：自动配置并启动 PM2 和 Nginx 服务
# 支持：宝塔面板和标准 Nginx 环境

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
DOMAIN="taotech.com.hk"

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

# 检查是否只是诊断模式
if [ "$1" = "check" ] || [ "$1" = "diagnose" ]; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}网站诊断模式${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # 检查权限
    if [ "$EUID" -ne 0 ]; then 
        SUDO="sudo"
    else
        SUDO=""
    fi
    
    # 1. 检查 SSL 证书
    echo -e "${BLUE}[1/6]${NC} 检查 SSL 证书..."
    SSL_CERT=""
    SSL_KEY=""
    
    if [ "$IS_BT_PANEL" = true ] && [ -f "${BT_CERT_PATH}/fullchain.pem" ]; then
        SSL_CERT="${BT_CERT_PATH}/fullchain.pem"
        SSL_KEY="${BT_CERT_PATH}/privkey.pem"
        echo -e "${GREEN}✓${NC} 宝塔面板 SSL 证书存在"
    elif [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        SSL_CERT="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
        SSL_KEY="/etc/letsencrypt/live/$DOMAIN/privkey.pem"
        echo -e "${GREEN}✓${NC} Let's Encrypt SSL 证书存在"
    else
        echo -e "${RED}❌ SSL 证书不存在${NC}"
    fi
    
    if [ ! -z "$SSL_CERT" ]; then
        echo "  证书: $SSL_CERT"
        echo "  密钥: $SSL_KEY"
        CERT_EXPIRY=$($SUDO openssl x509 -enddate -noout -in "$SSL_CERT" 2>/dev/null | cut -d= -f2 || echo "无法读取")
        echo "  过期时间: $CERT_EXPIRY"
    fi
    echo ""
    
    # 2. 检查端口监听
    echo -e "${BLUE}[2/6]${NC} 检查端口监听..."
    if command -v ss &> /dev/null; then
        PORT_80=$(ss -tlnp 2>/dev/null | grep ':80 ' || echo "")
        PORT_443=$(ss -tlnp 2>/dev/null | grep ':443 ' || echo "")
        PORT_8080=$(ss -tlnp 2>/dev/null | grep ':8080 ' || echo "")
    elif command -v netstat &> /dev/null; then
        PORT_80=$(netstat -tlnp 2>/dev/null | grep ':80 ' || echo "")
        PORT_443=$(netstat -tlnp 2>/dev/null | grep ':443 ' || echo "")
        PORT_8080=$(netstat -tlnp 2>/dev/null | grep ':8080 ' || echo "")
    else
        PORT_80=""
        PORT_443=""
        PORT_8080=""
    fi
    
    [ ! -z "$PORT_80" ] && echo -e "${GREEN}✓${NC} 端口 80 正在监听" || echo -e "${RED}❌ 端口 80 未监听${NC}"
    [ ! -z "$PORT_443" ] && echo -e "${GREEN}✓${NC} 端口 443 正在监听" || echo -e "${RED}❌ 端口 443 未监听${NC}"
    [ ! -z "$PORT_8080" ] && echo -e "${GREEN}✓${NC} 端口 8080 正在监听" || echo -e "${RED}❌ 端口 8080 未监听${NC}"
    echo ""
    
    # 3. 检查 PM2 应用
    echo -e "${BLUE}[3/6]${NC} 检查 PM2 应用..."
    if command -v pm2 &> /dev/null; then
        if pm2 list 2>/dev/null | grep -q "$APP_NAME.*online"; then
            echo -e "${GREEN}✓${NC} PM2 应用正在运行"
            pm2 list | grep "$APP_NAME"
        else
            echo -e "${RED}❌ PM2 应用未运行${NC}"
        fi
    else
        echo -e "${YELLOW}⚠${NC} PM2 未安装"
    fi
    echo ""
    
    # 4. 检查 Nginx 配置
    echo -e "${BLUE}[4/6]${NC} 检查 Nginx 配置..."
    if [ -f "$NGINX_CONFIG" ]; then
        echo -e "${GREEN}✓${NC} Nginx 配置文件存在: $NGINX_CONFIG"
        if grep -q "return 301" "$NGINX_CONFIG"; then
            echo -e "${GREEN}✓${NC} HTTP 到 HTTPS 重定向已配置"
        else
            echo -e "${YELLOW}⚠${NC} HTTP 到 HTTPS 重定向未配置"
        fi
        if grep -q "listen.*443.*ssl" "$NGINX_CONFIG"; then
            echo -e "${GREEN}✓${NC} HTTPS (443) 配置存在"
        else
            echo -e "${YELLOW}⚠${NC} HTTPS (443) 配置不存在"
        fi
    else
        echo -e "${RED}❌ Nginx 配置文件不存在${NC}"
    fi
    echo ""
    
    # 5. 测试 Nginx 配置
    echo -e "${BLUE}[5/6]${NC} 测试 Nginx 配置..."
    if [ "$IS_BT_PANEL" = true ] && [ -f "$NGINX_CMD" ]; then
        if $SUDO $NGINX_CMD -t 2>&1; then
            echo -e "${GREEN}✓${NC} Nginx 配置测试通过"
        else
            echo -e "${RED}❌ Nginx 配置测试失败${NC}"
        fi
    elif command -v nginx &> /dev/null; then
        if $SUDO nginx -t 2>&1; then
            echo -e "${GREEN}✓${NC} Nginx 配置测试通过"
        else
            echo -e "${RED}❌ Nginx 配置测试失败${NC}"
        fi
    else
        echo -e "${YELLOW}⚠${NC} Nginx 未安装"
    fi
    echo ""
    
    # 6. 测试访问
    echo -e "${BLUE}[6/6]${NC} 测试网站访问..."
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -L --connect-timeout 5 http://$DOMAIN 2>&1 || echo "000")
    if [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
        echo -e "${GREEN}✓${NC} HTTP 正确重定向到 HTTPS (状态码: $HTTP_STATUS)"
    elif [ "$HTTP_STATUS" = "200" ]; then
        echo -e "${YELLOW}⚠${NC} HTTP 返回 200（应该重定向到 HTTPS）"
    else
        echo -e "${RED}❌ HTTP 访问异常 (状态码: $HTTP_STATUS)${NC}"
    fi
    
    if [ ! -z "$SSL_CERT" ]; then
        HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -k --connect-timeout 5 https://$DOMAIN 2>&1 || echo "000")
        if [ "$HTTPS_STATUS" = "200" ]; then
            echo -e "${GREEN}✓${NC} HTTPS 访问正常 (状态码: $HTTPS_STATUS)"
        else
            echo -e "${RED}❌ HTTPS 访问失败 (状态码: $HTTPS_STATUS)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠${NC} HTTPS 未配置（无 SSL 证书）"
    fi
    echo ""
    
    exit 0
fi

# 正常启动流程
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
if command -v nginx &> /dev/null || [ -f "$NGINX_CMD" ] || [ "$IS_BT_PANEL" = true ]; then
    # 创建配置目录
    if [ "$IS_BT_PANEL" = false ]; then
        $SUDO mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled 2>/dev/null || true
    else
        $SUDO mkdir -p /www/server/panel/vhost/nginx 2>/dev/null || true
    fi
    
    # 检查是否有 SSL 证书（优先使用宝塔面板证书，然后是 Let's Encrypt）
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
        # 3. 尝试查找其他证书
        for cert_dir in /etc/letsencrypt/live/*/; do
            if [ -f "${cert_dir}fullchain.pem" ] && [ -f "${cert_dir}privkey.pem" ]; then
                SSL_CERT="${cert_dir}fullchain.pem"
                SSL_KEY="${cert_dir}privkey.pem"
                DOMAIN=$(basename "$cert_dir")
                echo -e "${GREEN}✓${NC} 检测到其他 SSL 证书"
                break
            fi
        done
    fi
    
    # 创建或更新配置文件（仅站点配置文件，不修改主配置文件）
    if [ ! -f "$NGINX_CONFIG" ] || [ "nginx.conf.example" -nt "$NGINX_CONFIG" ]; then
        echo "创建/更新 Nginx 站点配置..."
        echo "  配置文件路径: $NGINX_CONFIG"
        
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
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
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
        
        proxy_buffering off;
        proxy_request_buffering off;
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
        
        proxy_buffering off;
        proxy_request_buffering off;
    }
}
NGINX_EOF
            echo -e "${GREEN}✓${NC} HTTP 配置已创建"
            echo -e "${YELLOW}ℹ${NC} 如需 HTTPS，运行: ./setup-https.sh"
        fi
    fi
    
    # 启用配置（仅非宝塔面板需要）
    if [ "$IS_BT_PANEL" = false ] && [ ! -L "$NGINX_ENABLED" ]; then
        $SUDO ln -sf "$NGINX_CONFIG" "$NGINX_ENABLED"
    fi
    
    # 测试并重载
    echo "测试 Nginx 配置..."
    if $SUDO $NGINX_CMD -t 2>&1 | tee /tmp/nginx_test.log; then
        if [ "$IS_BT_PANEL" = true ]; then
            $SUDO $NGINX_CMD -s reload 2>/dev/null || $SUDO systemctl reload nginx 2>/dev/null || true
        else
            $SUDO systemctl reload nginx 2>/dev/null || $SUDO nginx -s reload 2>/dev/null || true
        fi
        echo -e "${GREEN}✓${NC} Nginx 配置已更新并重载"
    else
        echo -e "${RED}❌ Nginx 配置测试失败${NC}"
        echo ""
        echo -e "${YELLOW}错误信息:${NC}"
        $SUDO $NGINX_CMD -t 2>&1 | grep -E "error|emerg|failed" || true
        echo ""
        
        # 检查是否是主配置文件问题
        if [ "$IS_BT_PANEL" = true ]; then
            MAIN_CONF="/www/server/nginx/conf/nginx.conf"
            if grep -q "server {" "$MAIN_CONF" 2>/dev/null && ! grep -q "http {" "$MAIN_CONF" 2>/dev/null; then
                echo -e "${YELLOW}⚠${NC} 检测到主配置文件可能有问题"
                echo -e "${YELLOW}提示: 宝塔面板的主配置文件不应直接包含 server 块${NC}"
                echo -e "${YELLOW}建议: 在宝塔面板中检查主配置文件，或恢复默认配置${NC}"
            fi
        fi
        
        echo ""
        echo -e "${YELLOW}解决方案:${NC}"
        echo "1. 检查站点配置文件: $NGINX_CONFIG"
        echo "2. 如果使用宝塔面板，在面板中检查配置"
        echo "3. 运行诊断: ./start.sh check"
        exit 1
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
echo "  诊断: ${GREEN}./start.sh check${NC}"
echo ""
echo -e "${BLUE}访问地址:${NC}"
echo "  本地: ${GREEN}http://localhost:8080${NC}"

# 检查 HTTPS（443端口）
if [ -f "$NGINX_CONFIG" ] && grep -q "listen.*443.*ssl" "$NGINX_CONFIG"; then
    echo "  HTTP (80): ${GREEN}http://$DOMAIN${NC} (自动重定向到 HTTPS)"
    echo "  HTTPS (443): ${GREEN}https://$DOMAIN${NC}"
    if [ "$IS_BT_PANEL" = true ]; then
        echo -e "  ${YELLOW}提示: 宝塔面板配置位于: $NGINX_CONFIG${NC}"
    fi
else
    echo "  HTTP (80): ${GREEN}http://$DOMAIN${NC}"
    echo -e "  ${YELLOW}HTTPS (443): 未配置（运行 ./setup-https.sh 配置）${NC}"
fi
echo ""
