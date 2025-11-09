# HTTPS 免费证书配置指南

本指南将帮助您使用 Let's Encrypt 为网站配置免费的 HTTPS 证书。

## 📋 前置要求

1. **域名**：您需要拥有一个域名（例如：taotech.com）
2. **服务器**：Linux 服务器（Ubuntu/Debian 推荐）
3. **服务器访问权限**：SSH 访问权限和 root 或 sudo 权限
4. **域名解析**：域名已正确解析到服务器 IP 地址

## 🚀 方法一：使用 Certbot（推荐）

### 步骤 1：安装 Certbot

#### Ubuntu/Debian:
```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx
# 或者如果使用 Apache:
# sudo apt install certbot python3-certbot-apache
```

#### CentOS/RHEL:
```bash
sudo yum install certbot python3-certbot-nginx
```

### 步骤 2：获取证书

#### 如果使用 Nginx（推荐）：
```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

#### 如果使用 Apache：
```bash
sudo certbot --apache -d yourdomain.com -d www.yourdomain.com
```

#### 仅获取证书（手动配置）：
```bash
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com
```

证书将保存在：
- 证书文件：`/etc/letsencrypt/live/yourdomain.com/fullchain.pem`
- 私钥文件：`/etc/letsencrypt/live/yourdomain.com/privkey.pem`

### 步骤 3：配置自动续期

Let's Encrypt 证书有效期为 90 天，Certbot 会自动配置续期：

```bash
# 测试续期
sudo certbot renew --dry-run

# 查看续期状态
sudo systemctl status certbot.timer
```

## 🔧 方法二：使用 Node.js 直接配置 HTTPS

### 步骤 1：获取证书（使用 Certbot）

```bash
sudo certbot certonly --standalone -d yourdomain.com
```

### 步骤 2：更新 server.js

证书获取后，使用更新后的 `server.js`（已支持 HTTPS）。

### 步骤 3：设置文件权限

```bash
sudo chmod 644 /etc/letsencrypt/live/yourdomain.com/fullchain.pem
sudo chmod 600 /etc/letsencrypt/live/yourdomain.com/privkey.pem
```

### 步骤 4：启动 HTTPS 服务器

```bash
# 设置环境变量
export DOMAIN=yourdomain.com
export HTTPS_PORT=443
export HTTP_PORT=80

# 启动服务器
node server.js
```

## 🌐 方法三：使用 Nginx 反向代理（生产环境推荐）

### Nginx 配置示例

创建 `/etc/nginx/sites-available/taotech`：

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    # 重定向 HTTP 到 HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    # SSL 证书配置
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    # SSL 优化配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # 安全头
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # 反向代理到 Node.js 应用
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

启用配置：
```bash
sudo ln -s /etc/nginx/sites-available/taotech /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 🔄 证书自动续期

Certbot 会自动配置续期任务，但如果您使用 Node.js 直接服务 HTTPS，需要重启应用：

创建续期后钩子脚本 `/etc/letsencrypt/renewal-hooks/deploy/restart-nodejs.sh`：

```bash
#!/bin/bash
# 重启 Node.js 应用
systemctl restart taotech
# 或者使用 PM2:
# pm2 restart taotech
```

设置执行权限：
```bash
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/restart-nodejs.sh
```

## 📝 环境变量配置

创建 `.env` 文件（不要提交到 Git）：

```env
DOMAIN=yourdomain.com
HTTPS_PORT=443
HTTP_PORT=80
SSL_CERT_PATH=/etc/letsencrypt/live/yourdomain.com/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/yourdomain.com/privkey.pem
```

## 🛡️ 安全建议

1. **防火墙配置**：
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

2. **定期更新**：
   ```bash
   sudo apt update && sudo apt upgrade
   ```

3. **监控证书过期**：
   ```bash
   sudo certbot certificates
   ```

## 🐛 常见问题

### 问题 1：端口 80 被占用
```bash
# 检查占用
sudo lsof -i :80
# 停止占用进程或使用其他端口
```

### 问题 2：域名验证失败
- 确保域名 DNS 已正确解析到服务器 IP
- 确保防火墙允许端口 80 和 443
- 检查域名是否已正确配置

### 问题 3：证书续期失败
```bash
# 手动续期
sudo certbot renew --force-renewal
```

## 📚 更多资源

- [Let's Encrypt 官网](https://letsencrypt.org/)
- [Certbot 文档](https://certbot.eff.org/)
- [SSL Labs 测试](https://www.ssllabs.com/ssltest/) - 测试您的 SSL 配置

---

**注意**：在生产环境部署前，请确保：
1. 域名已正确解析
2. 服务器防火墙已配置
3. 已备份现有配置
4. 已测试证书续期流程

