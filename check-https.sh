#!/bin/bash

# HTTPS 访问诊断脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="taotech.com.hk"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}HTTPS 访问诊断: $DOMAIN${NC}"
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
CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ]; then
    echo -e "${GREEN}✓${NC} SSL 证书存在"
    echo "  证书: $CERT_PATH"
    echo "  私钥: $KEY_PATH"
    
    # 检查证书有效期
    CERT_EXPIRY=$(openssl x509 -enddate -noout -in "$CERT_PATH" 2>/dev/null | cut -d= -f2)
    if [ ! -z "$CERT_EXPIRY" ]; then
        echo "  有效期至: $CERT_EXPIRY"
    fi
else
    echo -e "${RED}❌${NC} SSL 证书不存在"
    echo "  请运行: sudo ./setup-https.sh"
fi
echo ""

# 2. 检查 Nginx 配置
echo -e "${BLUE}[2/6]${NC} 检查 Nginx 配置..."
NGINX_CONFIG="/etc/nginx/sites-available/taotech"

if [ -f "$NGINX_CONFIG" ]; then
    echo -e "${GREEN}✓${NC} Nginx 配置文件存在"
    
    # 检查 HTTPS 配置
    if grep -q "listen 443" "$NGINX_CONFIG"; then
        echo -e "${GREEN}✓${NC} HTTPS (443) 已配置"
        
        # 检查证书路径
        if grep -q "$DOMAIN" "$NGINX_CONFIG" || grep -q "ssl_certificate" "$NGINX_CONFIG"; then
            echo -e "${GREEN}✓${NC} SSL 证书路径已配置"
        else
            echo -e "${YELLOW}⚠${NC} SSL 证书路径可能未正确配置"
        fi
    else
        echo -e "${RED}❌${NC} HTTPS (443) 未配置"
    fi
    
    # 检查是否启用
    if [ -L "/etc/nginx/sites-enabled/taotech" ]; then
        echo -e "${GREEN}✓${NC} 配置已启用"
    else
        echo -e "${RED}❌${NC} 配置未启用"
        echo "  运行: sudo ln -s $NGINX_CONFIG /etc/nginx/sites-enabled/taotech"
    fi
else
    echo -e "${RED}❌${NC} Nginx 配置文件不存在"
fi
echo ""

# 3. 检查端口监听
echo -e "${BLUE}[3/6]${NC} 检查端口监听..."
echo ""

# 端口 443
if $SUDO lsof -i :443 2>/dev/null | grep -q LISTEN; then
    echo -e "${GREEN}✓${NC} 端口 443 正在监听"
    $SUDO lsof -i :443 | grep LISTEN | head -1
else
    echo -e "${RED}❌${NC} 端口 443 未监听"
fi

# 端口 80
if $SUDO lsof -i :80 2>/dev/null | grep -q LISTEN; then
    echo -e "${GREEN}✓${NC} 端口 80 正在监听"
    $SUDO lsof -i :80 | grep LISTEN | head -1
else
    echo -e "${YELLOW}⚠${NC} 端口 80 未监听"
fi

# 端口 8080
if $SUDO lsof -i :8080 2>/dev/null | grep -q LISTEN; then
    echo -e "${GREEN}✓${NC} 端口 8080 正在监听 (Node.js)"
    $SUDO lsof -i :8080 | grep LISTEN | head -1
else
    echo -e "${RED}❌${NC} 端口 8080 未监听 (Node.js 未运行)"
fi
echo ""

# 4. 检查 Nginx 状态
echo -e "${BLUE}[4/6]${NC} 检查 Nginx 服务..."
if command -v nginx &> /dev/null; then
    if systemctl is-active --quiet nginx 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Nginx 服务运行中"
    else
        echo -e "${RED}❌${NC} Nginx 服务未运行"
        echo "  运行: sudo systemctl start nginx"
    fi
    
    # 测试配置
    if $SUDO nginx -t 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Nginx 配置测试通过"
    else
        echo -e "${RED}❌${NC} Nginx 配置测试失败"
        $SUDO nginx -t
    fi
else
    echo -e "${RED}❌${NC} Nginx 未安装"
fi
echo ""

# 5. 检查防火墙
echo -e "${BLUE}[5/6]${NC} 检查防火墙..."
if command -v ufw &> /dev/null; then
    if $SUDO ufw status | grep -q "443/tcp"; then
        echo -e "${GREEN}✓${NC} UFW 已开放端口 443"
    else
        echo -e "${YELLOW}⚠${NC} UFW 未开放端口 443"
        echo "  运行: sudo ufw allow 443/tcp"
    fi
fi

if command -v firewall-cmd &> /dev/null; then
    if $SUDO firewall-cmd --list-ports 2>/dev/null | grep -q "443/tcp"; then
        echo -e "${GREEN}✓${NC} firewalld 已开放端口 443"
    else
        echo -e "${YELLOW}⚠${NC} firewalld 未开放端口 443"
    fi
fi
echo ""

# 6. 测试连接
echo -e "${BLUE}[6/6]${NC} 测试连接..."
echo ""

# 测试本地 HTTPS
if curl -s -k -o /dev/null -w "%{http_code}" https://localhost:443 --max-time 3 > /dev/null 2>&1; then
    HTTP_CODE=$(curl -s -k -o /dev/null -w "%{http_code}" https://localhost:443 --max-time 3)
    echo -e "${GREEN}✓${NC} 本地 HTTPS 连接成功 (HTTP $HTTP_CODE)"
else
    echo -e "${RED}❌${NC} 本地 HTTPS 连接失败"
fi

# 测试域名 HTTPS
if curl -s -k -o /dev/null -w "%{http_code}" https://$DOMAIN --max-time 5 > /dev/null 2>&1; then
    HTTP_CODE=$(curl -s -k -o /dev/null -w "%{http_code}" https://$DOMAIN --max-time 5)
    echo -e "${GREEN}✓${NC} 域名 HTTPS 连接成功 (HTTP $HTTP_CODE)"
    
    # 检查 SSL 证书
    echo ""
    echo "SSL 证书信息:"
    echo | openssl s_client -connect $DOMAIN:443 -servername $DOMAIN 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "无法获取证书信息"
else
    echo -e "${RED}❌${NC} 域名 HTTPS 连接失败"
    echo ""
    echo "可能的原因:"
    echo "  1. DNS 解析问题"
    echo "  2. 防火墙阻止"
    echo "  3. 云服务器安全组未开放 443"
    echo "  4. Nginx 未正确配置"
fi

echo ""

# 总结
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}诊断完成${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}快速修复:${NC}"
echo "1. 如果证书不存在: ${GREEN}sudo ./setup-https.sh${NC}"
echo "2. 如果 Nginx 未运行: ${GREEN}sudo systemctl start nginx${NC}"
echo "3. 如果配置未启用: ${GREEN}sudo ln -s /etc/nginx/sites-available/taotech /etc/nginx/sites-enabled/taotech${NC}"
echo "4. 如果防火墙未开放: ${GREEN}sudo ufw allow 443/tcp${NC}"
echo "5. 重启服务: ${GREEN}./start.sh${NC}"
echo ""

