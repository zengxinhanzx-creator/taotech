#!/bin/bash

# 修复 Nginx 404 错误脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}修复 Nginx 404 错误${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}⚠ 需要 sudo 权限${NC}"
    SUDO="sudo"
else
    SUDO=""
fi

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NGINX_CONFIG="/etc/nginx/sites-available/taotech"
NGINX_ENABLED="/etc/nginx/sites-enabled/taotech"

# 1. 检查 Node.js 应用是否运行
echo -e "${BLUE}[1/4]${NC} 检查 Node.js 应用..."
if lsof -ti :8080 &> /dev/null; then
    echo -e "${GREEN}✓${NC} Node.js 应用运行在端口 8080"
    
    # 测试本地连接
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 --max-time 2 | grep -q "200\|301\|302"; then
        echo -e "${GREEN}✓${NC} 本地连接正常"
    else
        echo -e "${RED}❌${NC} 本地连接失败，请检查 Node.js 应用"
    fi
else
    echo -e "${RED}❌${NC} Node.js 应用未运行"
    echo "  请先启动: pm2 start server.js --name taotech"
    exit 1
fi
echo ""

# 2. 检查 Nginx 配置
echo -e "${BLUE}[2/4]${NC} 检查 Nginx 配置..."
echo ""

if [ ! -f "$NGINX_CONFIG" ]; then
    echo -e "${YELLOW}⚠${NC} Nginx 配置文件不存在，正在创建..."
    
    if [ -f "$PROJECT_DIR/nginx.conf.example" ]; then
        # 创建配置目录
        $SUDO mkdir -p /etc/nginx/sites-available
        $SUDO mkdir -p /etc/nginx/sites-enabled
        
        # 复制配置
        $SUDO cp "$PROJECT_DIR/nginx.conf.example" "$NGINX_CONFIG"
        echo -e "${GREEN}✓${NC} 配置文件已创建"
    else
        echo -e "${RED}❌${NC} 未找到 nginx.conf.example"
        exit 1
    fi
fi

# 检查配置内容
if grep -q "proxy_pass.*8080" "$NGINX_CONFIG"; then
    echo -e "${GREEN}✓${NC} 配置包含反向代理设置"
else
    echo -e "${RED}❌${NC} 配置缺少反向代理设置"
    echo "  正在修复..."
    
    # 创建正确的配置
    $SUDO tee "$NGINX_CONFIG" > /dev/null << 'EOF'
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
EOF
    echo -e "${GREEN}✓${NC} 配置已修复"
fi

# 检查 server_name
if grep -q "server_name.*_" "$NGINX_CONFIG" || grep -q "server_name.*taotech" "$NGINX_CONFIG"; then
    echo -e "${GREEN}✓${NC} server_name 配置正确"
else
    echo -e "${YELLOW}⚠${NC} 建议设置 server_name 为 _ 或您的域名"
fi

echo ""

# 3. 启用配置
echo -e "${BLUE}[3/4]${NC} 启用 Nginx 配置..."
echo ""

if [ ! -L "$NGINX_ENABLED" ]; then
    echo "创建软链接..."
    $SUDO ln -s "$NGINX_CONFIG" "$NGINX_ENABLED" 2>/dev/null || {
        echo -e "${YELLOW}⚠${NC} 软链接已存在或创建失败"
    }
fi

if [ -L "$NGINX_ENABLED" ]; then
    echo -e "${GREEN}✓${NC} 配置已启用"
else
    echo -e "${YELLOW}⚠${NC} 配置未启用，手动创建:"
    echo "  $SUDO ln -s $NGINX_CONFIG $NGINX_ENABLED"
fi

echo ""

# 4. 测试并重载 Nginx
echo -e "${BLUE}[4/4]${NC} 测试并重载 Nginx..."
echo ""

if $SUDO nginx -t 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Nginx 配置测试通过"
    
    # 重载 Nginx
    if $SUDO systemctl reload nginx 2>/dev/null || $SUDO nginx -s reload 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Nginx 已重载"
    else
        echo -e "${YELLOW}⚠${NC} Nginx 重载失败，尝试重启..."
        $SUDO systemctl restart nginx 2>/dev/null || true
    fi
else
    echo -e "${RED}❌${NC} Nginx 配置测试失败"
    echo "  错误信息:"
    $SUDO nginx -t
    exit 1
fi

echo ""

# 显示配置摘要
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ 修复完成${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}配置摘要:${NC}"
echo "  配置文件: $NGINX_CONFIG"
echo "  启用链接: $NGINX_ENABLED"
echo "  反向代理: http://localhost:8080"
echo ""
echo -e "${BLUE}测试访问:${NC}"
echo "  本地: curl http://localhost"
echo "  外网: curl http://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_IP')"
echo ""
echo -e "${BLUE}如果仍有问题，检查:${NC}"
echo "  1. Node.js 应用是否运行: pm2 status"
echo "  2. 端口 8080 是否监听: sudo lsof -i :8080"
echo "  3. Nginx 错误日志: $SUDO tail -f /var/log/nginx/error.log"
echo ""

