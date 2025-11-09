#!/bin/bash

# TAO Technology 网站停止脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_NAME="taotech"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}停止 TAO Technology 网站服务${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 停止 PM2 应用
if command -v pm2 &> /dev/null; then
    if pm2 list | grep -q "$APP_NAME"; then
        echo "停止 PM2 应用..."
        pm2 stop "$APP_NAME"
        pm2 delete "$APP_NAME"
        echo -e "${GREEN}✓${NC} PM2 应用已停止"
    else
        echo -e "${YELLOW}⚠${NC} PM2 应用未运行"
    fi
else
    echo -e "${YELLOW}⚠${NC} PM2 未安装"
fi

echo ""
echo -e "${GREEN}✓ 停止完成${NC}"
echo ""

