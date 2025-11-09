#!/bin/bash

# 使用 Standalone 模式获取 Let's Encrypt 证书脚本
# 适用于没有 Nginx 的 Node.js 应用

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Let's Encrypt 证书获取工具 (Standalone 模式)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠ 请使用 sudo 运行此脚本"
    exit 1
fi

# 检查域名
read -p "请输入您的域名 (例如: taotech.com.hk): " DOMAIN
if [ -z "$DOMAIN" ]; then
    echo "❌ 域名不能为空"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "检查前置条件..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查 Certbot
if ! command -v certbot &> /dev/null; then
    echo "⚠ Certbot 未安装，正在安装..."
    
    if [ -f /etc/debian_version ]; then
        apt update
        apt install -y certbot
    elif [ -f /etc/redhat-release ]; then
        yum install -y certbot
    else
        echo "❌ 未识别的系统，请手动安装 Certbot"
        echo "访问: https://certbot.eff.org/"
        exit 1
    fi
fi

echo "✓ Certbot 已安装"

# 检查端口 80 占用
echo ""
echo "检查端口 80 占用情况..."
PORT_80_PROCESS=$(lsof -ti :80 2>/dev/null)

if [ ! -z "$PORT_80_PROCESS" ]; then
    echo "⚠ 检测到端口 80 被占用"
    echo "占用进程: $PORT_80_PROCESS"
    echo ""
    echo "需要临时停止占用 80 端口的服务以获取证书"
    echo ""
    echo "常见服务停止命令:"
    echo "  sudo systemctl stop nginx"
    echo "  sudo systemctl stop apache2"
    echo "  sudo systemctl stop httpd"
    echo ""
    read -p "是否现在停止这些服务? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 尝试停止常见服务
        systemctl stop nginx 2>/dev/null && echo "✓ 已停止 nginx"
        systemctl stop apache2 2>/dev/null && echo "✓ 已停止 apache2"
        systemctl stop httpd 2>/dev/null && echo "✓ 已停止 httpd"
        
        # 等待服务停止
        sleep 2
        
        # 再次检查
        PORT_80_PROCESS=$(lsof -ti :80 2>/dev/null)
        if [ ! -z "$PORT_80_PROCESS" ]; then
            echo "⚠ 端口 80 仍被占用，进程 ID: $PORT_80_PROCESS"
            read -p "是否强制终止该进程? (y/n): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                kill -9 $PORT_80_PROCESS 2>/dev/null
                echo "✓ 已终止进程"
                sleep 1
            else
                echo "❌ 无法继续，请手动停止占用 80 端口的服务"
                exit 1
            fi
        fi
    else
        echo "⚠ 请手动停止占用 80 端口的服务后重新运行此脚本"
        exit 1
    fi
else
    echo "✓ 端口 80 未被占用"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "获取 SSL 证书..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "请确保："
echo "  1. 域名 $DOMAIN 已解析到本服务器 IP"
echo "  2. 防火墙已开放端口 80 和 443"
echo "  3. 可以访问 http://$DOMAIN"
echo ""
read -p "按 Enter 继续获取证书..."

# 获取证书
echo ""
echo "正在获取证书..."
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
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "配置 Node.js 服务器"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
    echo "然后启动服务器："
    echo "  node server.js"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "证书自动续期"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "证书将每 90 天自动续期"
    echo "测试续期: sudo certbot renew --dry-run"
    echo ""
    echo "⚠ 注意: Standalone 模式续期时需要临时停止服务"
    echo "建议配置续期钩子脚本或使用 Webroot 模式"
    echo ""
    
    # 询问是否重启之前停止的服务
    read -p "是否重启之前停止的服务? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl start nginx 2>/dev/null && echo "✓ 已启动 nginx"
        systemctl start apache2 2>/dev/null && echo "✓ 已启动 apache2"
        systemctl start httpd 2>/dev/null && echo "✓ 已启动 httpd"
    fi
    
else
    echo ""
    echo "❌ 证书获取失败"
    echo ""
    echo "可能的原因："
    echo "  1. 域名 DNS 解析不正确"
    echo "  2. 端口 80 无法从外部访问"
    echo "  3. 防火墙阻止了连接"
    echo "  4. 域名验证失败"
    echo ""
    echo "请检查："
    echo "  - DNS 解析: dig $DOMAIN"
    echo "  - 端口访问: curl -I http://$DOMAIN"
    echo "  - 防火墙: sudo ufw status"
    echo ""
    echo "详细日志: /var/log/letsencrypt/letsencrypt.log"
fi

