# Nginx + Node.js 配置指南

本指南说明如何配置 Nginx 作为反向代理，让 Nginx 监听 80 端口，Node.js 应用运行在其他端口。

## 📋 架构说明

```
用户请求 (端口 80) 
    ↓
Nginx (反向代理)
    ↓
Node.js 应用 (端口 8080)
```

## 🚀 快速配置步骤

### 步骤 1: 确保 Node.js 应用使用端口 8080

Node.js 应用已配置为默认使用端口 8080（不需要 root 权限）。

```bash
# 启动应用（使用 PM2）
pm2 start server.js --name taotech

# 或直接运行
node server.js
```

应用将在 `http://localhost:8080` 运行。

### 步骤 2: 配置 Nginx

#### 2.1 创建配置文件

```bash
sudo nano /etc/nginx/sites-available/taotech
```

复制 `nginx.conf.example` 的内容，或使用以下配置：

```nginx
server {
    listen 80;
    server_name taotech.com.hk www.taotech.com.hk;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

#### 2.2 启用配置

```bash
# 创建软链接
sudo ln -s /etc/nginx/sites-available/taotech /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重新加载 Nginx
sudo systemctl reload nginx
```

### 步骤 3: 验证配置

```bash
# 检查 Nginx 状态
sudo systemctl status nginx

# 检查端口占用
sudo lsof -i :80    # 应该是 nginx
sudo lsof -i :8080  # 应该是 node

# 测试连接
curl http://localhost:8080  # 直接访问 Node.js
curl http://localhost:80    # 通过 Nginx 访问
```

## 🔧 详细配置说明

### HTTP 配置（端口 80）

```nginx
server {
    listen 80;
    server_name taotech.com.hk www.taotech.com.hk;
    
    # 反向代理到 Node.js
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### HTTPS 配置（端口 443）

如果使用 SSL 证书：

```nginx
server {
    listen 80;
    server_name taotech.com.hk www.taotech.com.hk;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name taotech.com.hk www.taotech.com.hk;

    # SSL 证书
    ssl_certificate /etc/letsencrypt/live/taotech.com.hk/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/taotech.com.hk/privkey.pem;
    
    # SSL 配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # 反向代理
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 🔄 使用 Certbot 自动配置 SSL

如果使用 Let's Encrypt：

```bash
# 安装 Certbot
sudo apt install certbot python3-certbot-nginx

# 自动配置（Certbot 会修改 Nginx 配置）
sudo certbot --nginx -d taotech.com.hk -d www.taotech.com.hk
```

Certbot 会自动：
- 获取 SSL 证书
- 配置 Nginx HTTPS
- 设置 HTTP 到 HTTPS 重定向
- 配置自动续期

## 📊 端口分配

| 服务 | 端口 | 说明 |
|------|------|------|
| **Nginx** | 80 (HTTP) | 对外服务端口 |
| **Nginx** | 443 (HTTPS) | SSL 端口 |
| **Node.js** | 8080 | 内部应用端口 |

## ✅ 验证配置

### 1. 检查服务状态

```bash
# Nginx
sudo systemctl status nginx

# Node.js (PM2)
pm2 status

# Node.js (systemd)
sudo systemctl status taotech
```

### 2. 测试连接

```bash
# 直接访问 Node.js（应该工作）
curl http://localhost:8080

# 通过 Nginx 访问（应该工作）
curl http://localhost:80
curl http://taotech.com.hk
```

### 3. 检查日志

```bash
# Nginx 访问日志
sudo tail -f /var/log/nginx/access.log

# Nginx 错误日志
sudo tail -f /var/log/nginx/error.log

# Node.js 日志 (PM2)
pm2 logs taotech
```

## 🛠️ 常见问题

### 问题 1: 502 Bad Gateway

**原因**: Node.js 应用未运行或端口不匹配

**解决**:
```bash
# 检查 Node.js 是否运行
pm2 status

# 检查端口
sudo lsof -i :8080

# 重启 Node.js
pm2 restart taotech
```

### 问题 2: 403 Forbidden

**原因**: Nginx 权限问题

**解决**:
```bash
# 检查文件权限
ls -la /www/wwwroot/taotech.com.hk

# 检查 Nginx 用户
grep user /etc/nginx/nginx.conf
```

### 问题 3: 端口冲突

**原因**: 其他服务占用端口

**解决**:
```bash
# 检查端口占用
sudo lsof -i :80
sudo lsof -i :8080

# 停止占用服务
sudo systemctl stop <service-name>
```

## 🔄 重启服务

### 重启 Nginx

```bash
sudo systemctl restart nginx
# 或
sudo systemctl reload nginx  # 不中断服务
```

### 重启 Node.js

```bash
# PM2
pm2 restart taotech

# systemd
sudo systemctl restart taotech
```

## 📝 配置文件位置

- **Nginx 配置**: `/etc/nginx/sites-available/taotech`
- **启用链接**: `/etc/nginx/sites-enabled/taotech`
- **Nginx 主配置**: `/etc/nginx/nginx.conf`
- **日志**: `/var/log/nginx/`

## 🎯 最佳实践

1. **使用 PM2 管理 Node.js**: 自动重启、日志管理
2. **Nginx 作为反向代理**: 处理静态文件、SSL、负载均衡
3. **分离端口**: Nginx 80/443，Node.js 8080
4. **启用 HTTPS**: 使用 Let's Encrypt 免费证书
5. **监控日志**: 定期检查 Nginx 和 Node.js 日志

## 📚 相关文档

- `nginx.conf.example` - Nginx 配置示例
- `RUN_BACKGROUND.md` - PM2 后台运行指南
- `HTTPS_SETUP.md` - HTTPS 证书配置
- `CONNECTION_ERROR_FIX.md` - 连接问题排查

---

**提示**: 这种架构（Nginx + Node.js）是生产环境的标准配置，既安全又高效。

