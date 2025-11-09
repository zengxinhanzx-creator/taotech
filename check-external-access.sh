#!/bin/bash

# 检查外网访问配置脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}外网访问检查工具${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then 
    SUDO="sudo"
else
    SUDO=""
fi

# 1. 检查服务是否运行
echo -e "${BLUE}[1/6]${NC} 检查服务状态..."
echo ""

# PM2 状态
if command -v pm2 &> /dev/null || [ -f "$(npm config get prefix)/bin/pm2" ]; then
    PM2_CMD=$(command -v pm2 2>/dev/null || echo "$(npm config get prefix)/bin/pm2")
    if $PM2_CMD list 2>/dev/null | grep -q "taotech.*online"; then
        echo -e "${GREEN}✓${NC} PM2 应用运行中"
    else
        echo -e "${RED}❌${NC} PM2 应用未运行"
    fi
else
    echo -e "${YELLOW}⚠${NC} PM2 未安装"
fi

# 端口检查
echo ""
echo -e "${BLUE}[2/6]${NC} 检查端口监听..."
echo ""

# 检查端口 8080
if $SUDO lsof -i :8080 2>/dev/null | grep -q LISTEN; then
    echo -e "${GREEN}✓${NC} 端口 8080 正在监听"
    LISTEN_INFO=$($SUDO lsof -i :8080 2>/dev/null | grep LISTEN | head -1)
    echo "  $LISTEN_INFO"
    
    # 检查监听地址
    if echo "$LISTEN_INFO" | grep -q "0.0.0.0:8080\|*:8080"; then
        echo -e "${GREEN}✓${NC} 监听所有网络接口（0.0.0.0）"
    elif echo "$LISTEN_INFO" | grep -q "127.0.0.1:8080\|localhost:8080"; then
        echo -e "${RED}❌${NC} 只监听本地（127.0.0.1），外网无法访问"
        echo "  需要修改 server.js 监听 0.0.0.0"
    fi
else
    echo -e "${RED}❌${NC} 端口 8080 未监听"
fi

# 检查端口 80
if $SUDO lsof -i :80 2>/dev/null | grep -q LISTEN; then
    echo -e "${GREEN}✓${NC} 端口 80 正在监听（Nginx）"
    LISTEN_INFO=$($SUDO lsof -i :80 2>/dev/null | grep LISTEN | head -1)
    echo "  $LISTEN_INFO"
else
    echo -e "${YELLOW}⚠${NC} 端口 80 未监听（可能需要 Nginx）"
fi

echo ""

# 3. 检查防火墙
echo -e "${BLUE}[3/6]${NC} 检查防火墙..."
echo ""

# UFW
if command -v ufw &> /dev/null; then
    UFW_STATUS=$($SUDO ufw status 2>/dev/null | head -1)
    echo "UFW 状态: $UFW_STATUS"
    
    if echo "$UFW_STATUS" | grep -q "active"; then
        if $SUDO ufw status | grep -q "80/tcp\|8080/tcp"; then
            echo -e "${GREEN}✓${NC} 防火墙已开放端口 80/8080"
        else
            echo -e "${RED}❌${NC} 防火墙未开放端口 80/8080"
            echo "  运行以下命令开放端口:"
            echo "    $SUDO ufw allow 80/tcp"
            echo "    $SUDO ufw allow 8080/tcp"
        fi
    else
        echo -e "${YELLOW}⚠${NC} UFW 防火墙未启用"
    fi
else
    echo -e "${YELLOW}⚠${NC} UFW 未安装"
fi

# firewalld (CentOS/RHEL)
if command -v firewall-cmd &> /dev/null; then
    if $SUDO firewall-cmd --state 2>/dev/null | grep -q "running"; then
        echo "firewalld 状态: 运行中"
        if $SUDO firewall-cmd --list-ports 2>/dev/null | grep -q "80/tcp\|8080/tcp"; then
            echo -e "${GREEN}✓${NC} firewalld 已开放端口"
        else
            echo -e "${RED}❌${NC} firewalld 未开放端口"
            echo "  运行: $SUDO firewall-cmd --permanent --add-port=80/tcp"
            echo "       $SUDO firewall-cmd --permanent --add-port=8080/tcp"
            echo "       $SUDO firewall-cmd --reload"
        fi
    fi
fi

echo ""

# 4. 检查 Nginx 配置
echo -e "${BLUE}[4/6]${NC} 检查 Nginx 配置..."
echo ""

if command -v nginx &> /dev/null; then
    if [ -f "/etc/nginx/sites-available/taotech" ]; then
        echo -e "${GREEN}✓${NC} Nginx 配置文件存在"
        
        # 检查 server_name
        SERVER_NAME=$(grep -oP 'server_name \K[^;]+' /etc/nginx/sites-available/taotech 2>/dev/null | head -1 | tr -d ' ')
        if [ ! -z "$SERVER_NAME" ]; then
            echo "  server_name: $SERVER_NAME"
        fi
        
        # 检查 proxy_pass
        if grep -q "proxy_pass.*8080" /etc/nginx/sites-available/taotech; then
            echo -e "${GREEN}✓${NC} Nginx 反向代理配置正确"
        else
            echo -e "${YELLOW}⚠${NC} Nginx 反向代理配置可能不正确"
        fi
        
        # 检查是否启用
        if [ -L "/etc/nginx/sites-enabled/taotech" ]; then
            echo -e "${GREEN}✓${NC} Nginx 配置已启用"
        else
            echo -e "${YELLOW}⚠${NC} Nginx 配置未启用"
            echo "  运行: $SUDO ln -s /etc/nginx/sites-available/taotech /etc/nginx/sites-enabled/"
        fi
    else
        echo -e "${YELLOW}⚠${NC} Nginx 配置文件不存在"
    fi
else
    echo -e "${YELLOW}⚠${NC} Nginx 未安装"
fi

echo ""

# 5. 获取服务器 IP
echo -e "${BLUE}[5/6]${NC} 服务器网络信息..."
echo ""

# 获取公网 IP
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "无法获取")
if [ "$PUBLIC_IP" != "无法获取" ]; then
    echo -e "${GREEN}✓${NC} 公网 IP: $PUBLIC_IP"
else
    echo -e "${YELLOW}⚠${NC} 无法获取公网 IP"
fi

# 获取内网 IP
INTERNAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ip addr show | grep -oP 'inet \K[\d.]+' | grep -v '127.0.0.1' | head -1)
if [ ! -z "$INTERNAL_IP" ]; then
    echo -e "${GREEN}✓${NC} 内网 IP: $INTERNAL_IP"
fi

echo ""

# 6. 测试连接
echo -e "${BLUE}[6/6]${NC} 连接测试..."
echo ""

# 本地测试
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 --max-time 2 > /dev/null 2>&1; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 --max-time 2)
    echo -e "${GREEN}✓${NC} 本地连接成功 (HTTP $HTTP_CODE)"
else
    echo -e "${RED}❌${NC} 本地连接失败"
fi

# 内网测试
if [ ! -z "$INTERNAL_IP" ]; then
    if curl -s -o /dev/null -w "%{http_code}" http://$INTERNAL_IP:8080 --max-time 2 > /dev/null 2>&1; then
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$INTERNAL_IP:8080 --max-time 2)
        echo -e "${GREEN}✓${NC} 内网连接成功 (HTTP $HTTP_CODE)"
    else
        echo -e "${RED}❌${NC} 内网连接失败"
    fi
fi

# 外网测试（通过 80 端口）
if [ ! -z "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "无法获取" ]; then
    if curl -s -o /dev/null -w "%{http_code}" http://$PUBLIC_IP:80 --max-time 5 > /dev/null 2>&1; then
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$PUBLIC_IP:80 --max-time 5)
        echo -e "${GREEN}✓${NC} 外网连接成功 (HTTP $HTTP_CODE)"
    else
        echo -e "${RED}❌${NC} 外网连接失败"
    fi
fi

echo ""

# 总结和建议
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}诊断完成${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}常见问题和解决方案:${NC}"
echo ""
echo "1. ${YELLOW}防火墙未开放端口${NC}"
echo "   UFW: $SUDO ufw allow 80/tcp && $SUDO ufw allow 8080/tcp"
echo "   firewalld: $SUDO firewall-cmd --permanent --add-port=80/tcp --add-port=8080/tcp && $SUDO firewall-cmd --reload"
echo ""
echo "2. ${YELLOW}云服务器安全组未开放${NC}"
echo "   需要在云服务商控制台开放端口 80 和 8080"
echo ""
echo "3. ${YELLOW}服务器只监听本地${NC}"
echo "   检查 server.js 是否监听 0.0.0.0（已自动处理）"
echo ""
echo "4. ${YELLOW}Nginx 未配置或未启动${NC}"
echo "   运行: $SUDO systemctl start nginx"
echo "   检查: $SUDO nginx -t"
echo ""
echo -e "${BLUE}访问地址:${NC}"
if [ ! -z "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "无法获取" ]; then
    echo "  外网: http://$PUBLIC_IP"
    echo "  外网(8080): http://$PUBLIC_IP:8080"
fi
if [ ! -z "$INTERNAL_IP" ]; then
    echo "  内网: http://$INTERNAL_IP:8080"
fi
echo "  本地: http://localhost:8080"
echo ""

