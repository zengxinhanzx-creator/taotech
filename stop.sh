#!/bin/bash

# TAO Technology 网站停止脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 默认项目目录
DEFAULT_DIR="/www/wwwroot/taotech.com.hk"
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 如果当前目录不是默认目录，尝试使用默认目录
if [ "$PROJECT_DIR" != "$DEFAULT_DIR" ] && [ -d "$DEFAULT_DIR" ]; then
    PROJECT_DIR="$DEFAULT_DIR"
fi

cd "$PROJECT_DIR"

APP_NAME="taotech"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}停止 TAO Technology 网站服务${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检测 PM2 命令
NPM_GLOBAL_PATH=$(npm config get prefix 2>/dev/null || echo "$HOME/.npm-global")
PM2_PATH="$NPM_GLOBAL_PATH/bin/pm2"

if [ -f "$PM2_PATH" ]; then
    PM2_CMD="$PM2_PATH"
elif command -v pm2 &> /dev/null; then
    PM2_CMD="pm2"
else
    PM2_CMD=""
fi

# 停止 PM2 应用
if [ ! -z "$PM2_CMD" ]; then
    if $PM2_CMD list 2>/dev/null | grep -q "$APP_NAME"; then
        echo "停止 PM2 应用..."
        $PM2_CMD stop "$APP_NAME" 2>/dev/null || true
        $PM2_CMD delete "$APP_NAME" 2>/dev/null || true
        echo -e "${GREEN}✓${NC} PM2 应用已停止"
    else
        echo -e "${YELLOW}⚠${NC} PM2 应用未运行"
    fi
else
    echo -e "${YELLOW}⚠${NC} PM2 未安装或未找到"
fi

echo ""
echo -e "${GREEN}✓ 停止完成${NC}"
echo ""
