#!/bin/bash

# 网站访问诊断脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="taotech.com.hk"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}网站访问诊断${NC}"
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
SSL_CERT="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
SSL_KEY="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

if [ -f "$SSL_CERT" ] && [ -f "$SSL_KEY" ]; then
    echo -e "${GREEN}✓${NC} SSL 证书存在"
    echo "  证书: $SSL_CERT"
    echo "  密钥: $SSL_KEY"
    CERT_EXPIRY=$($SUDO openssl x509 -enddate -noout -in "$SSL_CERT" 2>/dev/null | cut -d= -f2)
    echo "  过期时间: $CERT_EXPIRY"
else
    echo -e "${RED}❌ SSL 证书不存在${NC}"
    echo "  证书路径: $SSL_CERT"
    echo -e "  ${YELLOW}提示: 运行 ./setup-https.sh 获取证书${NC}"
fi
echo ""

# 2. 检查端口监听
echo -e "${BLUE}[2/5]${NC} 检查端口监听..."
if command -v netstat &> /dev/null; then
    PORT_80=$(netstat -tlnp 2>/dev/null | grep ':80 ' || echo "")
    PORT_443=$(netstat -tlnp 2>/dev/null | grep ':443 ' || echo "")
elif command -v ss &> /dev/null; then
    PORT_80=$(ss -tlnp 2>/dev/null | grep ':80 ' || echo "")
    PORT_443=$(ss -tlnp 2>/dev/null | grep ':443 ' || echo "")
else
    PORT_80=""
    PORT_443=""
fi

if [ ! -z "$PORT_80" ]; then
    echo -e "${GREEN}✓${NC} 端口 80 正在监听"
    echo "  $PORT_80"
else
    echo -e "${RED}❌ 端口 80 未监听${NC}"
fi

if [ ! -z "$PORT_443" ]; then
    echo -e "${GREEN}✓${NC} 端口 443 正在监听"
    echo "  $PORT_443"
else
    echo -e "${RED}❌ 端口 443 未监听${NC}"
fi
echo ""

# 3. 检查 Nginx 配置
echo -e "${BLUE}[3/5]${NC} 检查 Nginx 配置..."
NGINX_CONFIG="/etc/nginx/sites-available/taotech"
NGINX_ENABLED="/etc/nginx/sites-enabled/taotech"

if [ -f "$NGINX_CONFIG" ]; then
    echo -e "${GREEN}✓${NC} Nginx 配置文件存在"
    
    # 检查 HTTP 重定向
    if grep -q "return 301" "$NGINX_CONFIG"; then
        echo -e "${GREEN}✓${NC} HTTP 到 HTTPS 重定向已配置"
    else
        echo -e "${YELLOW}⚠${NC} HTTP 到 HTTPS 重定向未配置"
    fi
    
    # 检查 HTTPS 配置
    if grep -q "listen.*443.*ssl" "$NGINX_CONFIG"; then
        echo -e "${GREEN}✓${NC} HTTPS (443) 配置存在"
    else
        echo -e "${RED}❌ HTTPS (443) 配置不存在${NC}"
    fi
    
    # 显示配置摘要
    echo ""
    echo "配置摘要:"
    grep -E "listen|server_name|ssl_certificate" "$NGINX_CONFIG" | sed 's/^/  /'
else
    echo -e "${RED}❌ Nginx 配置文件不存在${NC}"
fi

if [ -L "$NGINX_ENABLED" ]; then
    echo -e "${GREEN}✓${NC} Nginx 配置已启用"
else
    echo -e "${YELLOW}⚠${NC} Nginx 配置未启用（需要创建符号链接）"
fi
echo ""

# 4. 测试 Nginx 配置
echo -e "${BLUE}[4/5]${NC} 测试 Nginx 配置..."
if command -v nginx &> /dev/null; then
    if $SUDO nginx -t 2>&1; then
        echo -e "${GREEN}✓${NC} Nginx 配置测试通过"
    else
        echo -e "${RED}❌ Nginx 配置测试失败${NC}"
    fi
else
    echo -e "${YELLOW}⚠${NC} Nginx 未安装"
fi
echo ""

# 5. 检查防火墙
echo -e "${BLUE}[5/5]${NC} 检查防火墙规则..."
if command -v firewall-cmd &> /dev/null; then
    if $SUDO firewall-cmd --list-ports 2>/dev/null | grep -q "80/tcp"; then
        echo -e "${GREEN}✓${NC} 防火墙已开放 80 端口"
    else
        echo -e "${YELLOW}⚠${NC} 防火墙未开放 80 端口"
    fi
    
    if $SUDO firewall-cmd --list-ports 2>/dev/null | grep -q "443/tcp"; then
        echo -e "${GREEN}✓${NC} 防火墙已开放 443 端口"
    else
        echo -e "${YELLOW}⚠${NC} 防火墙未开放 443 端口"
    fi
elif command -v ufw &> /dev/null; then
    if $SUDO ufw status 2>/dev/null | grep -q "80/tcp"; then
        echo -e "${GREEN}✓${NC} UFW 已开放 80 端口"
    else
        echo -e "${YELLOW}⚠${NC} UFW 未开放 80 端口"
    fi
    
    if $SUDO ufw status 2>/dev/null | grep -q "443/tcp"; then
        echo -e "${GREEN}✓${NC} UFW 已开放 443 端口"
    else
        echo -e "${YELLOW}⚠${NC} UFW 未开放 443 端口"
    fi
else
    echo -e "${YELLOW}⚠${NC} 未检测到防火墙工具（可能是云服务器，需要在控制台配置安全组）"
fi
echo ""

# 6. 测试访问
echo -e "${BLUE}[6/6]${NC} 测试网站访问..."
echo "测试 HTTP 访问..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -L http://$DOMAIN 2>&1 || echo "000")
if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${YELLOW}⚠${NC} HTTP 返回 200（应该重定向到 HTTPS）"
elif [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
    echo -e "${GREEN}✓${NC} HTTP 正确重定向到 HTTPS (状态码: $HTTP_STATUS)"
else
    echo -e "${RED}❌ HTTP 访问异常 (状态码: $HTTP_STATUS)${NC}"
fi

echo "测试 HTTPS 访问..."
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -k https://$DOMAIN 2>&1 || echo "000")
if [ "$HTTPS_STATUS" = "200" ]; then
    echo -e "${GREEN}✓${NC} HTTPS 访问正常 (状态码: $HTTPS_STATUS)"
else
    echo -e "${RED}❌ HTTPS 访问失败 (状态码: $HTTPS_STATUS)${NC}"
    echo "  可能原因:"
    echo "    1. 443 端口未监听"
    echo "    2. 防火墙/安全组未开放 443 端口"
    echo "    3. SSL 证书配置错误"
fi
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}诊断完成${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

