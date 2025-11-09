#!/bin/bash

# HTTPS 证书快速设置脚本
# 使用 Let's Encrypt Certbot 获取免费 SSL 证书

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "HTTPS 证书设置向导"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠ 请使用 sudo 运行此脚本"
    exit 1
fi

# 检查域名
read -p "请输入您的域名 (例如: taotech.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
    echo "❌ 域名不能为空"
    exit 1
fi

echo ""
echo "正在安装 Certbot..."

# 检测系统类型并安装 Certbot
if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu
    apt update
    apt install -y certbot
elif [ -f /etc/redhat-release ]; then
    # CentOS/RHEL
    yum install -y certbot
else
    echo "⚠ 未识别的系统，请手动安装 Certbot"
    echo "访问: https://certbot.eff.org/"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "获取 SSL 证书..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "请确保："
echo "1. 域名已解析到本服务器 IP"
echo "2. 防火墙已开放端口 80 和 443"
echo "3. 端口 80 未被其他服务占用"
echo ""
read -p "按 Enter 继续..."

# 获取证书
certbot certonly --standalone -d $DOMAIN -d www.$DOMAIN

if [ $? -eq 0 ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✓ 证书获取成功！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "证书位置："
    echo "  证书: /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    echo "  私钥: /etc/letsencrypt/live/$DOMAIN/privkey.pem"
    echo ""
    echo "设置环境变量："
    echo "  export DOMAIN=$DOMAIN"
    echo "  export SSL_CERT_PATH=/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    echo "  export SSL_KEY_PATH=/etc/letsencrypt/live/$DOMAIN/privkey.pem"
    echo "  export NODE_ENV=production"
    echo ""
    echo "或创建 .env 文件："
    echo "  DOMAIN=$DOMAIN"
    echo "  SSL_CERT_PATH=/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    echo "  SSL_KEY_PATH=/etc/letsencrypt/live/$DOMAIN/privkey.pem"
    echo "  NODE_ENV=production"
    echo ""
    echo "证书将每 90 天自动续期"
    echo "测试续期: sudo certbot renew --dry-run"
else
    echo ""
    echo "❌ 证书获取失败"
    echo "请检查："
    echo "1. 域名 DNS 解析是否正确"
    echo "2. 端口 80 是否可访问"
    echo "3. 防火墙设置"
fi

