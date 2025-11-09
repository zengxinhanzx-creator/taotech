#!/bin/bash

# 检查并关闭占用80端口的服务脚本

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "端口 80 占用检查工具"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检测操作系统
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
else
    OS="Unknown"
fi

echo "检测到系统: $OS"
echo ""

# 检查80端口占用情况
echo "正在检查端口 80 的占用情况..."
echo ""

if [ "$OS" == "Linux" ]; then
    # Linux 系统
    echo "使用 netstat 检查:"
    sudo netstat -tlnp | grep :80 || echo "  未发现监听80端口的服务"
    
    echo ""
    echo "使用 ss 检查:"
    sudo ss -tlnp | grep :80 || echo "  未发现监听80端口的服务"
    
    echo ""
    echo "使用 lsof 检查:"
    sudo lsof -i :80 || echo "  未发现占用80端口的进程"
    
elif [ "$OS" == "macOS" ]; then
    # macOS 系统
    echo "使用 lsof 检查:"
    sudo lsof -i :80 || echo "  未发现占用80端口的进程"
    
    echo ""
    echo "使用 netstat 检查:"
    sudo netstat -an | grep LISTEN | grep :80 || echo "  未发现监听80端口的服务"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "常见占用80端口的服务及关闭方法:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 检查常见服务
services=("nginx" "apache2" "httpd" "lighttpd" "caddy")

for service in "${services[@]}"; do
    if command -v systemctl &> /dev/null; then
        # systemd 系统
        if systemctl is-active --quiet $service 2>/dev/null; then
            echo "发现运行中的服务: $service"
            echo "  停止命令: sudo systemctl stop $service"
            echo "  禁用命令: sudo systemctl disable $service"
            echo ""
        fi
    elif command -v service &> /dev/null; then
        # SysV init 系统
        if service $service status &> /dev/null; then
            echo "发现服务: $service"
            echo "  停止命令: sudo service $service stop"
            echo ""
        fi
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "操作选项:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. 临时停止 Nginx (获取证书后可以重启):"
echo "   sudo systemctl stop nginx"
echo ""
echo "2. 临时停止 Apache:"
echo "   sudo systemctl stop apache2  # Debian/Ubuntu"
echo "   sudo systemctl stop httpd    # CentOS/RHEL"
echo ""
echo "3. 停止所有占用80端口的进程 (危险，请谨慎使用):"
echo "   sudo fuser -k 80/tcp"
echo ""
echo "4. 查看具体进程并手动停止:"
echo "   sudo lsof -i :80"
echo "   sudo kill -9 <PID>"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "获取 Let's Encrypt 证书时的建议:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "方法1: 临时停止 Web 服务器"
echo "  sudo systemctl stop nginx"
echo "  sudo certbot certonly --standalone -d yourdomain.com"
echo "  sudo systemctl start nginx"
echo ""
echo "方法2: 使用 Webroot 模式 (不需要停止服务器)"
echo "  sudo certbot certonly --webroot -w /var/www/html -d yourdomain.com"
echo ""
echo "方法3: 使用 Nginx/Apache 插件 (自动配置)"
echo "  sudo certbot --nginx -d yourdomain.com"
echo "  sudo certbot --apache -d yourdomain.com"
echo ""

