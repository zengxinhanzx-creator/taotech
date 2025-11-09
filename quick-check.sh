#!/bin/bash

# 快速检查服务器状态脚本

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "服务器状态检查"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查 Node.js 进程
echo "1. 检查 Node.js 进程:"
NODE_PROCESS=$(ps aux | grep "node server.js" | grep -v grep)
if [ -z "$NODE_PROCESS" ]; then
    echo "   ❌ Node.js 服务器未运行"
else
    echo "   ✓ Node.js 服务器正在运行"
    echo "   $NODE_PROCESS"
fi
echo ""

# 检查 PM2
if command -v pm2 &> /dev/null; then
    echo "2. 检查 PM2 状态:"
    pm2 status
    echo ""
fi

# 检查 systemd
if systemctl is-active --quiet taotech 2>/dev/null; then
    echo "3. 检查 systemd 服务:"
    systemctl status taotech --no-pager -l
    echo ""
fi

# 检查端口 80
echo "4. 检查端口 80 占用:"
PORT_80=$(sudo lsof -i :80 2>/dev/null | head -2)
if [ -z "$PORT_80" ]; then
    echo "   ⚠ 端口 80 未被占用（服务器可能未运行）"
else
    echo "   ✓ 端口 80 被占用:"
    echo "$PORT_80"
fi
echo ""

# 测试本地连接
echo "5. 测试本地连接:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 --max-time 3 > /dev/null 2>&1; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80 --max-time 3)
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        echo "   ✓ 本地连接成功 (HTTP $HTTP_CODE)"
    else
        echo "   ⚠ 本地连接返回 HTTP $HTTP_CODE"
    fi
else
    echo "   ❌ 本地连接失败 (ERR_CONNECTION_CLOSED)"
fi
echo ""

# 检查文件权限
echo "6. 检查关键文件:"
if [ -f "server.js" ]; then
    echo "   ✓ server.js 存在"
    if [ -r "server.js" ]; then
        echo "   ✓ server.js 可读"
    else
        echo "   ❌ server.js 不可读"
    fi
else
    echo "   ❌ server.js 不存在"
fi

if [ -f "package.json" ]; then
    echo "   ✓ package.json 存在"
else
    echo "   ❌ package.json 不存在"
fi

if [ -d "node_modules" ]; then
    echo "   ✓ node_modules 存在"
else
    echo "   ❌ node_modules 不存在（需要运行 npm install）"
fi
echo ""

# 检查 Node.js 版本
echo "7. Node.js 环境:"
if command -v node &> /dev/null; then
    echo "   ✓ Node.js 版本: $(node -v)"
    echo "   ✓ npm 版本: $(npm -v)"
else
    echo "   ❌ Node.js 未安装"
fi
echo ""

# 检查防火墙
echo "8. 检查防火墙:"
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status 2>/dev/null | head -1)
    echo "   $UFW_STATUS"
    if echo "$UFW_STATUS" | grep -q "active"; then
        echo "   ⚠ 防火墙已启用，确保端口 80 已开放"
    fi
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "检查完成"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "如果服务器未运行，请执行:"
echo "  node server.js"
echo "  或"
echo "  pm2 start server.js --name taotech"
echo "  或"
echo "  sudo systemctl start taotech"
echo ""

