#!/bin/bash

# Nginx 主配置文件修复脚本
# 用于修复宝塔面板 Nginx 主配置文件被误修改的问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Nginx 主配置文件修复脚本${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查权限
if [ "$EUID" -ne 0 ]; then 
    SUDO="sudo"
else
    SUDO=""
fi

# 检测宝塔面板
if [ ! -d "/www/server/panel" ]; then
    echo -e "${RED}❌ 未检测到宝塔面板环境${NC}"
    echo "此脚本仅适用于宝塔面板环境"
    exit 1
fi

MAIN_CONF="/www/server/nginx/conf/nginx.conf"
BACKUP_CONF="${MAIN_CONF}.backup.$(date +%Y%m%d_%H%M%S)"

echo -e "${BLUE}[1/3]${NC} 检查主配置文件..."
if [ ! -f "$MAIN_CONF" ]; then
    echo -e "${RED}❌ 主配置文件不存在: $MAIN_CONF${NC}"
    exit 1
fi

# 备份原配置
echo -e "${BLUE}[2/3]${NC} 备份原配置文件..."
$SUDO cp "$MAIN_CONF" "$BACKUP_CONF"
echo -e "${GREEN}✓${NC} 已备份到: $BACKUP_CONF"

# 检查问题
echo -e "${BLUE}[3/3]${NC} 检查配置问题..."
if $SUDO /www/server/nginx/sbin/nginx -t 2>&1 | grep -q "server.*directive is not allowed"; then
    echo -e "${YELLOW}⚠${NC} 检测到主配置文件中有错误的 server 块"
    echo ""
    echo -e "${YELLOW}问题说明:${NC}"
    echo "宝塔面板的 Nginx 主配置文件不应直接包含 server 块"
    echo "server 块应该放在站点配置文件中: /www/server/panel/vhost/nginx/*.conf"
    echo ""
    echo -e "${YELLOW}解决方案:${NC}"
    echo "1. 检查主配置文件第14行附近是否有 server 块"
    echo "2. 如果有，需要将其移除或移动到站点配置文件"
    echo "3. 或者恢复宝塔面板的默认主配置文件"
    echo ""
    echo -e "${BLUE}查看主配置文件内容（前20行）:${NC}"
    $SUDO head -20 "$MAIN_CONF" | cat -n
    echo ""
    echo -e "${YELLOW}建议:${NC}"
    echo "1. 在宝塔面板中，进入 软件商店 → Nginx → 设置 → 配置修改"
    echo "2. 检查是否有错误的 server 块，如果有则删除"
    echo "3. 或者点击 重置配置 恢复默认配置"
    echo ""
    echo -e "${YELLOW}或者手动修复:${NC}"
    echo "编辑文件: $MAIN_CONF"
    echo "确保所有 server 块都在 http {} 块内，或者移除主配置文件中的 server 块"
    echo ""
else
    echo -e "${GREEN}✓${NC} 主配置文件语法检查通过"
    echo ""
    echo -e "${BLUE}测试 Nginx 配置:${NC}"
    if $SUDO /www/server/nginx/sbin/nginx -t; then
        echo -e "${GREEN}✓${NC} Nginx 配置测试通过"
    else
        echo -e "${RED}❌ Nginx 配置仍有问题${NC}"
        echo ""
        echo -e "${YELLOW}查看详细错误:${NC}"
        $SUDO /www/server/nginx/sbin/nginx -t 2>&1
    fi
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}修复脚本完成${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

