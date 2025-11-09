#!/bin/bash

# 快速安装 Node.js 依赖脚本

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TAO Technology 网站依赖安装工具"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ 错误: 未找到 Node.js"
    echo "请先安装 Node.js (版本 14.x 或更高)"
    echo ""
    echo "安装方法:"
    echo "  Ubuntu/Debian: curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs"
    echo "  CentOS/RHEL: curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash - && sudo yum install -y nodejs"
    exit 1
fi

# 检查 npm
if ! command -v npm &> /dev/null; then
    echo "❌ 错误: 未找到 npm"
    echo "npm 应该随 Node.js 一起安装"
    exit 1
fi

echo "✓ Node.js 版本: $(node -v)"
echo "✓ npm 版本: $(npm -v)"
echo ""

# 获取当前目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "当前目录: $SCRIPT_DIR"
echo ""

# 检查 package.json
if [ ! -f "package.json" ]; then
    echo "❌ 错误: 未找到 package.json 文件"
    echo "请确保在项目根目录运行此脚本"
    exit 1
fi

echo "✓ 找到 package.json"
echo ""

# 检查是否已有 node_modules
if [ -d "node_modules" ]; then
    echo "⚠ 检测到已存在的 node_modules 目录"
    read -p "是否重新安装? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "删除旧的 node_modules..."
        rm -rf node_modules
        rm -f package-lock.json
    fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "开始安装依赖..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 安装依赖
npm install

if [ $? -eq 0 ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✓ 依赖安装成功！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "已安装的依赖包:"
    echo "  - express: Web 框架"
    echo "  - body-parser: 请求体解析"
    echo ""
    echo "现在可以启动服务器:"
    echo "  node server.js"
    echo "  或"
    echo "  npm start"
    echo ""
    
    # 检查 submissions.txt
    if [ ! -f "submissions.txt" ]; then
        echo "创建 submissions.txt 文件..."
        touch submissions.txt
        chmod 666 submissions.txt
        echo "✓ submissions.txt 已创建"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "安装完成！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo ""
    echo "❌ 依赖安装失败"
    echo "请检查:"
    echo "  1. 网络连接"
    echo "  2. npm 配置"
    echo "  3. Node.js 版本 (需要 14.x 或更高)"
    exit 1
fi

