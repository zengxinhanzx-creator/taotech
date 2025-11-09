#!/bin/bash

# HTTPS SSL 证书快速配置脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}HTTPS SSL 证书配置${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查权限
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}⚠ 需要 sudo 权限${NC}"
    SUDO="sudo"
else
    SUDO=""
fi

# 获取域名
read -p "请输入您的域名 (例如: taotech.com.hk): " DOMAIN
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}❌ 域名不能为空${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}配置域名: ${GREEN}$DOMAIN${NC}"
echo ""

# 检查 Certbot
if ! command -v certbot &> /dev/null; then
    echo "安装 Certbot..."
    if [ -f /etc/debian_version ]; then
        $SUDO apt update
        $SUDO apt install -y certbot
    elif [ -f /etc/redhat-release ]; then
        $SUDO yum install -y certbot
    else
        echo -e "${RED}❌ 未识别的系统${NC}"
        exit 1
    fi
fi

# 检查端口 80 占用
if lsof -ti :80 &> /dev/null; then
    echo -e "${YELLOW}⚠ 端口 80 被占用，需要临时停止服务${NC}"
    echo "正在停止 Nginx..."
    $SUDO systemctl stop nginx 2>/dev/null || true
    sleep 2
fi

# 获取证书
echo "获取 SSL 证书..."
$SUDO certbot certonly --standalone -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN" 2>/dev/null || {
    echo -e "${YELLOW}⚠ 自动获取失败，使用交互模式...${NC}"
    $SUDO certbot certonly --standalone -d "$DOMAIN" -d "www.$DOMAIN"
}

# 检查证书
CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ]; then
    echo -e "${GREEN}✓${NC} 证书获取成功"
    echo "  证书: $CERT_PATH"
    echo "  私钥: $KEY_PATH"
else
    echo -e "${RED}❌ 证书获取失败${NC}"
    exit 1
fi

# 重启 Nginx（如果之前停止了）
if systemctl is-active --quiet nginx 2>/dev/null || [ -z "$($SUDO lsof -ti :80)" ]; then
    $SUDO systemctl start nginx 2>/dev/null || true
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ SSL 证书配置完成${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "请运行以下命令重启服务以启用 HTTPS:"
echo "  pm2 restart taotech"
echo "  或"
echo "  ./start.sh"
echo ""

