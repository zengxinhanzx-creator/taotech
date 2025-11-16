#!/bin/bash

# 本地开发环境启动脚本
# 用于 macOS 本地开发，不需要 Nginx 和 PM2

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}TAO Technology 网站 - 本地开发模式${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js 未安装${NC}"
    echo ""
    echo -e "${YELLOW}请先安装 Node.js：${NC}"
    echo "1. 使用 Homebrew: ${GREEN}brew install node${NC}"
    echo "2. 或从官网下载: ${GREEN}https://nodejs.org/${NC}"
    echo ""
    echo "详细说明请查看: ${GREEN}INSTALL_NODE.md${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Node.js: $(node -v)"
echo -e "${GREEN}✓${NC} npm: $(npm -v)"
echo ""

# 进入项目目录
cd "$(dirname "$0")"
PROJECT_DIR=$(pwd)

# 检查并安装依赖
echo -e "${BLUE}[1/2]${NC} 检查依赖..."
if [ ! -d "node_modules" ]; then
    echo "正在安装依赖..."
    npm install
    echo -e "${GREEN}✓${NC} 依赖安装完成"
else
    echo -e "${GREEN}✓${NC} 依赖已存在"
fi
echo ""

# 启动服务器
echo -e "${BLUE}[2/2]${NC} 启动服务器..."
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}服务器正在启动...${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}访问地址:${NC}"
echo -e "  ${GREEN}http://localhost:8080${NC}"
echo ""
echo -e "${YELLOW}按 Ctrl+C 停止服务器${NC}"
echo ""

# 设置环境变量为开发模式
export NODE_ENV=development
export PORT=8080

# 启动服务器
node server.js

