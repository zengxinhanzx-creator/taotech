# SSL 证书状态说明

## 📋 当前状态

如果您看到 "⚠ SSL 證書未找到，使用 HTTP 模式" 的提示，这是**正常**的。

### 开发环境（本地）

- ✅ **这是正常的**：本地开发时不需要 SSL 证书
- ✅ **功能正常**：所有功能都可以正常使用
- ✅ **无需操作**：可以继续开发

### 生产环境（服务器）

如果您的网站已部署到生产服务器，建议配置 SSL 证书以启用 HTTPS。

## 🚀 快速启用 HTTPS

### 方法 1: 使用自动脚本（推荐）

```bash
cd /www/wwwroot/taotech.com.hk
sudo ./get-cert-standalone.sh
```

脚本会自动：
- 检查并安装 Certbot
- 处理端口占用
- 获取 SSL 证书
- 提供配置说明

### 方法 2: 手动获取证书

```bash
# 1. 安装 Certbot
sudo apt install certbot

# 2. 获取证书（Standalone 模式）
sudo certbot certonly --standalone -d taotech.com.hk -d www.taotech.com.hk

# 3. 设置环境变量
export DOMAIN=taotech.com.hk
export NODE_ENV=production

# 4. 重启服务器
pm2 restart taotech
```

### 方法 3: 使用 Webroot 模式（无需停止服务）

```bash
sudo certbot certonly --webroot -w /www/wwwroot/taotech.com.hk -d taotech.com.hk
```

## ✅ 验证 SSL 证书

获取证书后，服务器会自动检测并启用 HTTPS：

```
✓ HTTPS 服務器運行在 https://localhost:443
✓ SSL 證書: /etc/letsencrypt/live/taotech.com.hk/fullchain.pem
```

## 🔍 检查证书状态

```bash
# 查看证书信息
sudo certbot certificates

# 测试证书续期
sudo certbot renew --dry-run
```

## 📝 环境变量配置

生产环境建议创建 `.env` 文件：

```env
DOMAIN=taotech.com.hk
SSL_CERT_PATH=/etc/letsencrypt/live/taotech.com.hk/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/taotech.com.hk/privkey.pem
NODE_ENV=production
```

## ❓ 常见问题

### Q: 本地开发需要 SSL 证书吗？

A: **不需要**。本地开发使用 HTTP 即可，所有功能正常。

### Q: 生产环境必须使用 HTTPS 吗？

A: **强烈建议**。HTTPS 提供：
- 数据加密
- 身份验证
- SEO 优势
- 浏览器信任

### Q: 证书获取失败怎么办？

A: 参考 `CERTBOT_FIX.md` 文件中的故障排除指南。

### Q: 证书会自动续期吗？

A: 是的，Let's Encrypt 证书每 90 天自动续期。

## 📚 相关文档

- `HTTPS_SETUP.md` - 完整的 HTTPS 配置指南
- `CERTBOT_FIX.md` - Certbot 错误修复指南
- `get-cert-standalone.sh` - 自动获取证书脚本

---

**提示**: 如果只是本地开发，可以忽略 SSL 证书警告，所有功能都正常工作。

