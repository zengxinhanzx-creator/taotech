# Certbot Nginx 错误修复指南

当遇到 `nginx: [emerg] open() "/etc/nginx/nginx.conf" failed` 错误时，说明系统可能没有安装 Nginx 或配置文件路径不同。

## 🔍 问题分析

错误原因：
- Nginx 未安装
- Nginx 配置文件路径不同
- 使用了错误的 Certbot 插件模式

## ✅ 解决方案

### 方案 1: 使用 Standalone 模式（推荐，无需 Nginx）

如果您没有使用 Nginx，可以使用 Standalone 模式获取证书：

```bash
# 1. 确保 80 端口未被占用（参考 PORT_80_GUIDE.md）
sudo lsof -i :80

# 2. 如果有服务占用 80 端口，临时停止
sudo systemctl stop nginx    # 如果安装了 nginx
sudo systemctl stop apache2  # 如果安装了 apache

# 3. 使用 standalone 模式获取证书
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# 4. 重启之前停止的服务（如果有）
sudo systemctl start nginx
```

### 方案 2: 使用 Webroot 模式（无需停止服务）

如果您的网站已经在运行，可以使用 Webroot 模式：

```bash
# 假设网站根目录是 /www/wwwroot/taotech.com.hk
sudo certbot certonly --webroot -w /www/wwwroot/taotech.com.hk -d yourdomain.com -d www.yourdomain.com
```

### 方案 3: 安装并配置 Nginx

如果您想使用 Nginx 作为反向代理：

#### 步骤 1: 安装 Nginx

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nginx

# CentOS/RHEL
sudo yum install nginx
```

#### 步骤 2: 启动 Nginx

```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

#### 步骤 3: 配置 Nginx

创建配置文件 `/etc/nginx/sites-available/taotech`：

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    root /www/wwwroot/taotech.com.hk;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
```

启用配置：

```bash
# Debian/Ubuntu
sudo ln -s /etc/nginx/sites-available/taotech /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# CentOS/RHEL (配置文件路径不同)
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
# 编辑 /etc/nginx/nginx.conf 添加 server 块
sudo nginx -t
sudo systemctl reload nginx
```

#### 步骤 4: 使用 Certbot Nginx 插件

```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

### 方案 4: 检查 Nginx 配置文件路径

不同系统的 Nginx 配置路径可能不同：

```bash
# 查找 nginx 配置文件
sudo find /etc -name "nginx.conf" 2>/dev/null
sudo find /usr -name "nginx.conf" 2>/dev/null

# 检查 nginx 是否安装
which nginx
nginx -v

# 查看 nginx 配置测试
sudo nginx -t
```

如果配置文件在其他位置，可以指定路径：

```bash
sudo certbot --nginx --nginx-server-root /custom/nginx/path -d yourdomain.com
```

## 🚀 快速修复（推荐流程）

对于您的 Node.js 应用，推荐使用 **Standalone 模式**：

```bash
# 1. 检查并停止占用 80 端口的服务
sudo lsof -i :80
# 如果有服务，临时停止（例如 nginx, apache2）

# 2. 获取证书（Standalone 模式）
sudo certbot certonly --standalone -d taotech.com.hk -d www.taotech.com.hk

# 3. 证书位置
# /etc/letsencrypt/live/taotech.com.hk/fullchain.pem
# /etc/letsencrypt/live/taotech.com.hk/privkey.pem

# 4. 配置环境变量或更新 server.js 中的证书路径
export DOMAIN=taotech.com.hk
export SSL_CERT_PATH=/etc/letsencrypt/live/taotech.com.hk/fullchain.pem
export SSL_KEY_PATH=/etc/letsencrypt/live/taotech.com.hk/privkey.pem
export NODE_ENV=production

# 5. 启动 Node.js 服务器（会自动检测证书并使用 HTTPS）
node server.js
```

## 📝 证书续期

使用 Standalone 模式获取的证书，续期时需要临时停止服务：

```bash
# 创建续期脚本
sudo nano /etc/letsencrypt/renewal-hooks/deploy/restart-nodejs.sh
```

脚本内容：

```bash
#!/bin/bash
# 停止 Node.js 应用（使用 PM2）
pm2 stop taotech || true

# 或者如果使用 systemd
# systemctl stop taotech || true
```

```bash
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/restart-nodejs.sh
```

或者使用 Webroot 模式续期（推荐，无需停止服务）：

```bash
# 修改续期配置使用 webroot
sudo certbot renew --webroot -w /www/wwwroot/taotech.com.hk
```

## 🔄 从 Nginx 模式切换到 Standalone 模式

如果您之前尝试使用 Nginx 插件但失败了，可以：

1. **取消之前的尝试**：
```bash
# 清理可能的部分配置
sudo certbot delete --cert-name yourdomain.com
```

2. **使用 Standalone 模式重新获取**：
```bash
sudo certbot certonly --standalone -d yourdomain.com
```

## ✅ 验证证书

获取证书后，验证：

```bash
# 查看证书信息
sudo certbot certificates

# 测试续期（不会实际续期）
sudo certbot renew --dry-run
```

## 🛠️ 常见问题

### Q: 为什么不能使用 Nginx 插件？

A: 如果您的应用是纯 Node.js，不需要 Nginx。使用 Standalone 或 Webroot 模式更简单。

### Q: Standalone 模式需要停止服务吗？

A: 是的，获取证书时需要临时停止占用 80 端口的服务。但续期时可以配置自动处理。

### Q: 如何避免每次续期都停止服务？

A: 使用 Webroot 模式，或配置续期钩子脚本自动处理。

---

**推荐**: 对于 Node.js 应用，使用 **Standalone 模式** 或 **Webroot 模式**，无需安装和配置 Nginx。

