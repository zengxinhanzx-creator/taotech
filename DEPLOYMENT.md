# 部署指南

本指南将帮助您在生产服务器上部署 TAO Technology 网站。

## 📋 前置要求

1. **Node.js**: 版本 14.x 或更高（推荐 18.x 或 20.x）
2. **npm**: Node.js 包管理器
3. **服务器访问权限**: SSH 访问和文件上传权限
4. **域名**: 已配置的域名（可选，用于 HTTPS）

## 🚀 快速部署步骤

### 步骤 1: 上传文件到服务器

将项目文件上传到服务器目录，例如：
```bash
/www/wwwroot/taotech.com.hk/
```

### 步骤 2: 安装 Node.js 依赖

**这是关键步骤！** 必须在项目目录中运行：

```bash
cd /www/wwwroot/taotech.com.hk
npm install
```

这将安装 `package.json` 中定义的所有依赖包，包括：
- `express` - Web 框架
- `body-parser` - 请求体解析中间件

### 步骤 3: 验证安装

检查 `node_modules` 目录是否已创建：

```bash
ls -la node_modules/
```

### 步骤 4: 启动服务器

```bash
# 开发模式
node server.js

# 或使用 npm 脚本
npm start
```

### 步骤 5: 使用进程管理器（生产环境推荐）

#### 使用 PM2（推荐）

```bash
# 安装 PM2
npm install -g pm2

# 启动应用
pm2 start server.js --name taotech

# 查看状态
pm2 status

# 设置开机自启
pm2 startup
pm2 save
```

#### 使用 systemd

创建服务文件 `/etc/systemd/system/taotech.service`：

```ini
[Unit]
Description=TAO Technology Website
After=network.target

[Service]
Type=simple
User=www
WorkingDirectory=/www/wwwroot/taotech.com.hk
ExecStart=/usr/bin/node /www/wwwroot/taotech.com.hk/server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=80

[Install]
WantedBy=multi-user.target
```

启用并启动服务：

```bash
sudo systemctl daemon-reload
sudo systemctl enable taotech
sudo systemctl start taotech
sudo systemctl status taotech
```

## 🔧 常见问题解决

### 问题 1: Cannot find module 'express'

**原因**: 未安装 Node.js 依赖包

**解决方法**:
```bash
cd /www/wwwroot/taotech.com.hk
npm install
```

### 问题 2: 权限错误

**解决方法**:
```bash
# 确保有写入权限
chmod -R 755 /www/wwwroot/taotech.com.hk
chown -R www:www /www/wwwroot/taotech.com.hk
```

### 问题 3: 端口被占用

**解决方法**:
```bash
# 检查端口占用
lsof -i :80

# 修改 server.js 中的端口号，或使用环境变量
export PORT=3000
node server.js
```

### 问题 4: submissions.txt 文件权限

**解决方法**:
```bash
touch /www/wwwroot/taotech.com.hk/submissions.txt
chmod 666 /www/wwwroot/taotech.com.hk/submissions.txt
chown www:www /www/wwwroot/taotech.com.hk/submissions.txt
```

## 🌐 配置 Nginx 反向代理

如果使用 Nginx 作为反向代理，配置示例：

```nginx
server {
    listen 80;
    server_name taotech.com.hk www.taotech.com.hk;
    
    location / {
        proxy_pass http://localhost:80;
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

## 🔐 配置 HTTPS

参考 `HTTPS_SETUP.md` 文件配置 SSL 证书。

## 📝 环境变量配置

创建 `.env` 文件（可选）：

```env
NODE_ENV=production
PORT=80
DOMAIN=taotech.com.hk
```

## 🔄 更新部署

当代码更新后：

```bash
# 1. 拉取最新代码（如果使用 Git）
cd /www/wwwroot/taotech.com.hk
git pull origin main

# 2. 重新安装依赖（如果有新依赖）
npm install

# 3. 重启服务
pm2 restart taotech
# 或
sudo systemctl restart taotech
```

## 📊 监控和日志

### PM2 日志

```bash
# 查看日志
pm2 logs taotech

# 查看实时日志
pm2 logs taotech --lines 100
```

### systemd 日志

```bash
# 查看服务日志
sudo journalctl -u taotech -f
```

## ✅ 部署检查清单

- [ ] Node.js 已安装（版本 14+）
- [ ] 已运行 `npm install` 安装依赖
- [ ] `node_modules` 目录存在
- [ ] 服务器可以正常启动
- [ ] 端口已正确配置
- [ ] 文件权限已设置
- [ ] 进程管理器已配置（PM2 或 systemd）
- [ ] Nginx 反向代理已配置（如使用）
- [ ] HTTPS 证书已配置（如使用）
- [ ] 防火墙规则已配置
- [ ] 域名 DNS 已正确解析

## 🆘 获取帮助

如果遇到问题：

1. 检查 Node.js 版本：`node -v`
2. 检查 npm 版本：`npm -v`
3. 查看错误日志
4. 确认所有依赖已安装：`npm list`
5. 检查文件权限和路径

---

**重要提示**: 每次部署或更新代码后，确保运行 `npm install` 以安装所有必需的依赖包！

