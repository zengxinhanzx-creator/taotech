# 如何关闭占用 80 端口的服务

在获取 Let's Encrypt SSL 证书时，Certbot 需要临时使用 80 端口来验证域名所有权。如果 80 端口被其他服务占用，需要先停止这些服务。

## 🔍 检查端口占用

### Linux 系统

```bash
# 方法1: 使用 lsof
sudo lsof -i :80

# 方法2: 使用 netstat
sudo netstat -tlnp | grep :80

# 方法3: 使用 ss (推荐)
sudo ss -tlnp | grep :80

# 方法4: 使用 fuser
sudo fuser 80/tcp
```

### macOS 系统

```bash
# 使用 lsof
sudo lsof -i :80

# 使用 netstat
sudo netstat -an | grep LISTEN | grep :80
```

## 🛑 关闭常见服务

### Nginx

```bash
# 停止服务
sudo systemctl stop nginx

# 或者 (SysV init)
sudo service nginx stop

# 禁用开机自启 (可选)
sudo systemctl disable nginx
```

### Apache

```bash
# Debian/Ubuntu
sudo systemctl stop apache2

# CentOS/RHEL
sudo systemctl stop httpd

# 或者 (SysV init)
sudo service apache2 stop
sudo service httpd stop
```

### 其他 Web 服务器

```bash
# Lighttpd
sudo systemctl stop lighttpd

# Caddy
sudo systemctl stop caddy
```

## ⚡ 快速停止所有占用 80 端口的进程

**⚠️ 警告：此方法会强制终止所有占用 80 端口的进程，请谨慎使用！**

```bash
# Linux
sudo fuser -k 80/tcp

# 或者手动查找并终止
sudo lsof -i :80
sudo kill -9 <PID>
```

## 📋 获取证书的三种方法

### 方法 1: 临时停止服务（Standalone 模式）

```bash
# 1. 停止 Web 服务器
sudo systemctl stop nginx

# 2. 获取证书
sudo certbot certonly --standalone -d yourdomain.com

# 3. 重启 Web 服务器
sudo systemctl start nginx
```

### 方法 2: 使用 Webroot 模式（推荐，无需停止服务）

```bash
# 不需要停止服务器，Certbot 会在网站目录创建验证文件
sudo certbot certonly --webroot -w /var/www/html -d yourdomain.com
```

### 方法 3: 使用 Nginx/Apache 插件（自动配置）

```bash
# Nginx - 自动配置 SSL 并重启服务
sudo certbot --nginx -d yourdomain.com

# Apache - 自动配置 SSL 并重启服务
sudo certbot --apache -d yourdomain.com
```

## 🔄 证书续期时的处理

证书续期通常不需要停止服务，Certbot 会自动处理：

```bash
# 测试续期（不会实际续期）
sudo certbot renew --dry-run

# 实际续期
sudo certbot renew
```

如果使用 Webroot 或插件模式，续期时不需要停止服务。

## 🛠️ 使用检查脚本

项目包含了一个检查脚本，可以自动检测占用 80 端口的服务：

```bash
./check-port-80.sh
```

## 📝 常见问题

### Q: 为什么需要停止服务？

A: Standalone 模式需要 Certbot 自己监听 80 端口来响应 Let's Encrypt 的验证请求。如果 80 端口被占用，验证会失败。

### Q: 停止服务会影响网站吗？

A: 是的，在 Standalone 模式下，停止服务期间网站会暂时无法访问。建议：
- 在低峰期操作
- 使用 Webroot 模式（无需停止服务）
- 使用 Nginx/Apache 插件（自动配置）

### Q: 如何避免每次续期都停止服务？

A: 使用 Webroot 模式或插件模式获取证书，这样续期时不需要停止服务。

### Q: 可以永久禁用占用 80 端口的服务吗？

A: 可以，但不推荐。如果不再需要该服务，可以：
```bash
sudo systemctl disable nginx
sudo systemctl stop nginx
```

## 🔐 安全建议

1. **使用 Webroot 模式**：避免服务中断
2. **设置自动续期**：Certbot 会自动配置
3. **监控证书过期**：定期检查证书状态
4. **备份配置**：修改前备份服务器配置

---

**提示**：如果您的网站正在运行，建议使用 Webroot 模式或插件模式，这样可以在不中断服务的情况下获取证书。

