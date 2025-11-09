#!/bin/bash

# TAO Technology 网站一键启动脚本
# 功能：自动启动 Nginx 和 PM2 服务

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目目录
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_NAME="taotech"
NGINX_CONFIG="/etc/nginx/sites-available/${APP_NAME}"
NGINX_ENABLED="/etc/nginx/sites-enabled/${APP_NAME}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}TAO Technology 网站一键启动脚本${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查是否为 root（某些操作需要）
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}⚠ 部分操作需要 sudo 权限${NC}"
    SUDO="sudo"
else
    SUDO=""
fi

# 进入项目目录
cd "$PROJECT_DIR"
echo -e "${GREEN}✓${NC} 项目目录: $PROJECT_DIR"
echo ""

# 1. 检查 Node.js 和 npm
echo -e "${BLUE}[1/7]${NC} 检查 Node.js 环境..."
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js 未安装${NC}"
    echo "请先安装 Node.js: https://nodejs.org/"
    exit 1
fi
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm 未安装${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Node.js: $(node -v)"
echo -e "${GREEN}✓${NC} npm: $(npm -v)"
echo ""

# 2. 安装依赖
echo -e "${BLUE}[2/7]${NC} 检查并安装依赖..."
if [ ! -d "node_modules" ]; then
    echo "正在安装依赖..."
    npm install
    echo -e "${GREEN}✓${NC} 依赖安装完成"
else
    echo -e "${GREEN}✓${NC} 依赖已存在"
fi
echo ""

# 3. 检查 PM2
echo -e "${BLUE}[3/7]${NC} 检查 PM2..."
if ! command -v pm2 &> /dev/null; then
    echo "PM2 未安装，正在安装..."
    npm install -g pm2
    echo -e "${GREEN}✓${NC} PM2 安装完成"
else
    echo -e "${GREEN}✓${NC} PM2: $(pm2 -v)"
fi
echo ""

# 4. 停止旧进程（如果存在）
echo -e "${BLUE}[4/7]${NC} 清理旧进程..."
if pm2 list | grep -q "$APP_NAME"; then
    echo "停止旧的 PM2 进程..."
    pm2 delete "$APP_NAME" 2>/dev/null || true
    sleep 1
fi

# 检查端口占用
if lsof -ti :8080 &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} 端口 8080 被占用，正在清理..."
    $SUDO lsof -ti :8080 | xargs $SUDO kill -9 2>/dev/null || true
    sleep 1
fi
echo -e "${GREEN}✓${NC} 清理完成"
echo ""

# 5. 启动 PM2 应用
echo -e "${BLUE}[5/7]${NC} 启动 Node.js 应用..."
if [ -f "ecosystem.config.js" ]; then
    pm2 start ecosystem.config.js
    echo -e "${GREEN}✓${NC} 使用 ecosystem.config.js 启动"
else
    pm2 start server.js --name "$APP_NAME"
    echo -e "${GREEN}✓${NC} 使用 server.js 启动"
fi

# 保存 PM2 进程列表
pm2 save 2>/dev/null || true

# 等待应用启动
sleep 2

# 检查应用状态
if pm2 list | grep -q "$APP_NAME.*online"; then
    echo -e "${GREEN}✓${NC} 应用启动成功"
else
    echo -e "${RED}❌ 应用启动失败，请查看日志: pm2 logs $APP_NAME${NC}"
    pm2 logs "$APP_NAME" --lines 20
    exit 1
fi
echo ""

# 6. 配置 Nginx（如果存在）
echo -e "${BLUE}[6/7]${NC} 配置 Nginx..."
if command -v nginx &> /dev/null; then
    # 检查 Nginx 配置是否存在
    if [ ! -f "$NGINX_CONFIG" ]; then
        echo -e "${YELLOW}⚠${NC} Nginx 配置文件不存在"
        if [ -f "nginx.conf.example" ]; then
            echo "从 nginx.conf.example 创建配置..."
            $SUDO cp nginx.conf.example "$NGINX_CONFIG"
            # 替换域名（如果需要）
            read -p "请输入您的域名 (直接回车跳过): " DOMAIN
            if [ ! -z "$DOMAIN" ]; then
                $SUDO sed -i "s/taotech.com.hk/$DOMAIN/g" "$NGINX_CONFIG"
                $SUDO sed -i "s/yourdomain.com/$DOMAIN/g" "$NGINX_CONFIG"
            fi
            echo -e "${GREEN}✓${NC} 配置文件已创建: $NGINX_CONFIG"
        else
            echo -e "${YELLOW}⚠${NC} 未找到 nginx.conf.example，跳过 Nginx 配置"
        fi
    fi
    
    # 启用配置
    if [ -f "$NGINX_CONFIG" ] && [ ! -L "$NGINX_ENABLED" ]; then
        echo "启用 Nginx 配置..."
        $SUDO ln -s "$NGINX_CONFIG" "$NGINX_ENABLED" 2>/dev/null || true
    fi
    
    # 测试 Nginx 配置
    if $SUDO nginx -t 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Nginx 配置测试通过"
        # 重载 Nginx
        $SUDO systemctl reload nginx 2>/dev/null || $SUDO nginx -s reload 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Nginx 已重载"
    else
        echo -e "${YELLOW}⚠${NC} Nginx 配置测试失败，请手动检查"
    fi
else
    echo -e "${YELLOW}⚠${NC} Nginx 未安装，跳过配置"
    echo "  如需使用 Nginx，请安装: sudo apt install nginx"
fi
echo ""

# 7. 显示服务状态
echo -e "${BLUE}[7/7]${NC} 服务状态检查..."
echo ""

# PM2 状态
echo -e "${BLUE}PM2 应用状态:${NC}"
pm2 list | grep "$APP_NAME" || echo "未找到应用"
echo ""

# 端口检查
echo -e "${BLUE}端口占用情况:${NC}"
if lsof -ti :8080 &> /dev/null; then
    echo -e "${GREEN}✓${NC} 端口 8080: Node.js 应用运行中"
    lsof -i :8080 | grep LISTEN
else
    echo -e "${RED}❌${NC} 端口 8080: 未监听"
fi

if lsof -ti :80 &> /dev/null; then
    echo -e "${GREEN}✓${NC} 端口 80: 服务运行中"
    lsof -i :80 | grep LISTEN | head -1
else
    echo -e "${YELLOW}⚠${NC} 端口 80: 未监听（可能需要 Nginx）"
fi
echo ""

# 测试连接
echo -e "${BLUE}连接测试:${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 --max-time 2 > /dev/null 2>&1; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 --max-time 2)
    echo -e "${GREEN}✓${NC} Node.js 应用响应正常 (HTTP $HTTP_CODE)"
else
    echo -e "${RED}❌${NC} Node.js 应用无响应"
fi
echo ""

# 完成
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ 启动完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}常用命令:${NC}"
echo "  查看日志: ${GREEN}pm2 logs $APP_NAME${NC}"
echo "  查看状态: ${GREEN}pm2 status${NC}"
echo "  重启: ${GREEN}pm2 restart $APP_NAME${NC}"
echo "  停止: ${GREEN}pm2 stop $APP_NAME${NC}"
echo ""
echo -e "${BLUE}访问地址:${NC}"
echo "  本地: ${GREEN}http://localhost:8080${NC}"
if [ -f "$NGINX_CONFIG" ]; then
    DOMAIN=$(grep -oP 'server_name \K[^;]+' "$NGINX_CONFIG" 2>/dev/null | head -1 | tr -d ' ')
    if [ ! -z "$DOMAIN" ] && [ "$DOMAIN" != "yourdomain.com" ]; then
        echo "  域名: ${GREEN}http://$DOMAIN${NC}"
    fi
fi
echo ""

