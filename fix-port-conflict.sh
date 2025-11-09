#!/bin/bash

# 修复端口冲突脚本

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "端口冲突修复工具"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PORT=8080

echo "检查端口 $PORT 占用情况..."
echo ""

# 检查端口占用
PORT_PROCESS=$(sudo lsof -ti :$PORT 2>/dev/null)

if [ -z "$PORT_PROCESS" ]; then
    echo "✓ 端口 $PORT 未被占用"
    echo ""
    echo "可能的原因："
    echo "  1. PM2 进程仍在运行但端口未释放"
    echo "  2. 之前的 Node.js 进程未正确关闭"
    echo ""
    echo "建议操作："
    echo "  pm2 delete taotech"
    echo "  sleep 2"
    echo "  pm2 start server.js --name taotech"
else
    echo "⚠ 端口 $PORT 被占用"
    echo ""
    echo "占用进程信息："
    sudo lsof -i :$PORT
    echo ""
    
    # 检查是否是 PM2 进程
    PM2_PID=$(ps aux | grep "node.*server.js" | grep -v grep | awk '{print $2}' | head -1)
    
    if [ ! -z "$PM2_PID" ]; then
        echo "发现 Node.js 进程 (PID: $PM2_PID)"
        read -p "是否停止该进程? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "停止进程 $PM2_PID..."
            kill $PM2_PID 2>/dev/null
            sleep 2
            
            # 检查是否还在运行
            if ps -p $PM2_PID > /dev/null 2>&1; then
                echo "强制停止..."
                kill -9 $PM2_PID 2>/dev/null
            fi
            
            echo "✓ 进程已停止"
        fi
    fi
    
    # 检查 PM2 进程
    if pm2 list | grep -q taotech; then
        echo ""
        echo "发现 PM2 进程 'taotech'"
        read -p "是否删除 PM2 进程? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            pm2 delete taotech
            echo "✓ PM2 进程已删除"
        fi
    fi
    
    echo ""
    echo "等待端口释放..."
    sleep 3
    
    # 再次检查
    PORT_PROCESS=$(sudo lsof -ti :$PORT 2>/dev/null)
    if [ -z "$PORT_PROCESS" ]; then
        echo "✓ 端口 $PORT 已释放"
    else
        echo "⚠ 端口 $PORT 仍被占用"
        echo "占用进程: $PORT_PROCESS"
        echo ""
        echo "手动停止："
        echo "  sudo kill -9 $PORT_PROCESS"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "建议操作"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. 清理所有 PM2 进程："
echo "   pm2 delete all"
echo ""
echo "2. 等待几秒后重新启动："
echo "   sleep 3"
echo "   pm2 start server.js --name taotech"
echo ""
echo "3. 或使用其他端口（修改 server.js 或设置环境变量）："
echo "   export PORT=3000"
echo "   pm2 start server.js --name taotech"
echo ""

