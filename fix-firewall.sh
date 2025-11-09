#!/bin/bash

# 一键开放防火墙端口脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}防火墙端口开放工具${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}⚠ 需要 sudo 权限${NC}"
    SUDO="sudo"
else
    SUDO=""
fi

# UFW 防火墙
if command -v ufw &> /dev/null; then
    echo -e "${BLUE}配置 UFW 防火墙...${NC}"
    
    # 检查状态
    UFW_STATUS=$($SUDO ufw status 2>/dev/null | head -1)
    echo "当前状态: $UFW_STATUS"
    
    if echo "$UFW_STATUS" | grep -q "inactive"; then
        echo -e "${YELLOW}⚠ UFW 未启用，是否启用? (y/n)${NC}"
        read -p "> " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            $SUDO ufw --force enable
        fi
    fi
    
    # 开放端口
    echo "开放端口 80 和 8080..."
    $SUDO ufw allow 80/tcp
    $SUDO ufw allow 8080/tcp
    $SUDO ufw allow 443/tcp  # HTTPS
    
    echo -e "${GREEN}✓${NC} 端口已开放"
    echo ""
    echo "当前规则:"
    $SUDO ufw status numbered
    echo ""
fi

# firewalld 防火墙 (CentOS/RHEL)
if command -v firewall-cmd &> /dev/null; then
    echo -e "${BLUE}配置 firewalld 防火墙...${NC}"
    
    if $SUDO firewall-cmd --state 2>/dev/null | grep -q "running"; then
        echo "开放端口 80, 443, 8080..."
        $SUDO firewall-cmd --permanent --add-port=80/tcp
        $SUDO firewall-cmd --permanent --add-port=443/tcp
        $SUDO firewall-cmd --permanent --add-port=8080/tcp
        $SUDO firewall-cmd --reload
        
        echo -e "${GREEN}✓${NC} 端口已开放"
        echo ""
        echo "当前开放的端口:"
        $SUDO firewall-cmd --list-ports
        echo ""
    else
        echo -e "${YELLOW}⚠ firewalld 未运行${NC}"
    fi
fi

# iptables (如果使用)
if command -v iptables &> /dev/null && ! command -v ufw &> /dev/null && ! command -v firewall-cmd &> /dev/null; then
    echo -e "${BLUE}配置 iptables...${NC}"
    echo -e "${YELLOW}⚠ 检测到 iptables，请手动配置:${NC}"
    echo "  $SUDO iptables -A INPUT -p tcp --dport 80 -j ACCEPT"
    echo "  $SUDO iptables -A INPUT -p tcp --dport 443 -j ACCEPT"
    echo "  $SUDO iptables -A INPUT -p tcp --dport 8080 -j ACCEPT"
    echo "  $SUDO iptables-save"
    echo ""
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ 防火墙配置完成${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}重要提示:${NC}"
echo "1. 如果仍然无法访问，请检查:"
echo "   - 云服务器安全组设置（阿里云、腾讯云、AWS 等）"
echo "   - 服务器是否监听 0.0.0.0（已修复）"
echo "   - Nginx 是否正常运行"
echo ""
echo "2. 云服务器安全组需要开放:"
echo "   - 端口 80 (HTTP)"
echo "   - 端口 443 (HTTPS)"
echo "   - 端口 8080 (Node.js，如果直接访问)"
echo ""

