# 宝塔面板 Nginx 配置指南

## 配置方式

宝塔面板有两种配置 Nginx 的方式：

### 方式1：使用站点配置文件（推荐）

宝塔面板会自动管理站点配置文件，位于：
```
/www/server/panel/vhost/nginx/taotech.com.hk.conf
```

**步骤：**

1. 在宝塔面板中，进入 **网站** → 找到 `taotech.com.hk` → 点击 **设置**

2. 选择 **配置文件** 标签

3. 将 `taotech.com.hk.bt.conf` 文件的内容复制到配置编辑器中

4. 根据实际情况修改 SSL 证书路径：
   - 如果使用 Let's Encrypt 证书：使用 `/etc/letsencrypt/live/taotech.com.hk/` 路径
   - 如果使用宝塔面板申请的证书：使用 `/www/server/panel/vhost/cert/taotech.com.hk/` 路径

5. 点击 **保存**，然后点击 **重载配置**

### 方式2：直接修改主配置文件

如果需要直接修改主配置文件 `/www/server/nginx/conf/nginx.conf`：

1. 备份原配置文件：
   ```bash
   cp /www/server/nginx/conf/nginx.conf /www/server/nginx/conf/nginx.conf.bak
   ```

2. 编辑配置文件：
   ```bash
   nano /www/server/nginx/conf/nginx.conf
   ```

3. 在 `http {}` 块中添加 `nginx.conf.bt` 文件中的 server 块

4. 测试配置：
   ```bash
   /www/server/nginx/sbin/nginx -t
   ```

5. 重载配置：
   ```bash
   /www/server/nginx/sbin/nginx -s reload
   ```

## SSL 证书配置

### 使用宝塔面板申请证书（推荐）

1. 在宝塔面板中，进入 **网站** → 找到 `taotech.com.hk` → 点击 **设置**

2. 选择 **SSL** 标签

3. 选择 **Let's Encrypt**，填写邮箱，点击 **申请**

4. 申请成功后，证书路径通常是：
   ```
   /www/server/panel/vhost/cert/taotech.com.hk/fullchain.pem
   /www/server/panel/vhost/cert/taotech.com.hk/privkey.pem
   ```

### 使用命令行申请的证书

如果使用 `setup-https.sh` 脚本申请的证书，路径是：
```
/etc/letsencrypt/live/taotech.com.hk/fullchain.pem
/etc/letsencrypt/live/taotech.com.hk/privkey.pem
```

## 配置说明

### HTTP 重定向
- HTTP (80端口) 自动重定向到 HTTPS (443端口)
- 确保所有访问都使用 HTTPS

### HTTPS 配置
- 使用标准 443 端口
- 支持 HTTP/2
- 配置了安全头和 SSL 优化

### 反向代理
- 所有请求转发到 Node.js 应用（端口 8080）
- 支持 WebSocket 升级
- 配置了适当的超时和缓冲设置

## 验证配置

1. 测试 Nginx 配置：
   ```bash
   /www/server/nginx/sbin/nginx -t
   ```

2. 检查端口监听：
   ```bash
   netstat -tlnp | grep -E ':(80|443) '
   ```

3. 测试访问：
   ```bash
   curl -I http://taotech.com.hk    # 应该返回 301 重定向
   curl -I https://taotech.com.hk   # 应该返回 200 OK
   ```

## 常见问题

### 1. 配置不生效
- 确保在宝塔面板中点击了 **重载配置**
- 检查配置文件语法是否正确
- 查看 Nginx 错误日志：`/www/wwwlogs/taotech.com.hk.error.log`

### 2. HTTPS 无法访问
- 检查 SSL 证书路径是否正确
- 检查 443 端口是否在监听
- 检查云服务器安全组是否开放 443 端口

### 3. 502 Bad Gateway
- 检查 Node.js 应用是否在运行（端口 8080）
- 检查 PM2 状态：`pm2 status`
- 查看应用日志：`pm2 logs taotech`

## 注意事项

1. **不要删除** 主配置文件中的 `include /www/server/panel/vhost/nginx/*.conf;` 这一行，这是宝塔面板自动管理站点配置的关键

2. 如果使用站点配置文件方式，宝塔面板会自动管理，建议使用这种方式

3. 修改配置后，务必测试配置语法，然后再重载

4. 建议定期备份配置文件

