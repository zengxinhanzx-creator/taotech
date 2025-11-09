# ERR_CONNECTION_CLOSED 错误排查指南

`ERR_CONNECTION_CLOSED` 错误表示连接被关闭，通常有以下几种原因。

## 🔍 快速排查步骤

### 步骤 1: 检查服务器是否运行

```bash
# 检查 Node.js 进程
ps aux | grep "node server.js"

# 如果使用 PM2
pm2 status

# 如果使用 systemd
sudo systemctl status taotech
```

### 步骤 2: 检查端口是否被占用

```bash
# 检查端口 80
sudo lsof -i :80
# 或
sudo netstat -tlnp | grep 80

# 检查是否有其他服务占用
sudo ss -tlnp | grep 80
```

### 步骤 3: 检查服务器日志

```bash
# PM2 日志
pm2 logs taotech --lines 50

# systemd 日志
sudo journalctl -u taotech -n 50

# 如果直接运行，查看控制台输出
```

### 步骤 4: 测试本地连接

```bash
# 测试本地连接
curl http://localhost:80

# 或
curl http://127.0.0.1:80
```

## 🛠️ 常见原因和解决方案

### 原因 1: 服务器未启动

**症状**: `ps aux | grep node` 没有输出

**解决**:
```bash
# 启动服务器
cd /www/wwwroot/taotech.com.hk
node server.js

# 或使用 PM2
pm2 start server.js --name taotech

# 或使用 systemd
sudo systemctl start taotech
```

### 原因 2: 服务器崩溃

**症状**: 进程存在但无法连接

**解决**:
```bash
# 查看错误日志
pm2 logs taotech --err

# 重启服务
pm2 restart taotech

# 或
sudo systemctl restart taotech
```

### 原因 3: 端口被其他服务占用

**症状**: `lsof -i :80` 显示其他进程

**解决**:
```bash
# 查找占用进程
sudo lsof -i :80

# 停止占用进程（例如 Nginx）
sudo systemctl stop nginx

# 或修改服务器端口
export PORT=8080
node server.js
```

### 原因 4: 权限不足（端口 80 需要 root）

**症状**: 服务器启动失败，提示 "EACCES: permission denied"

**解决**:
```bash
# 使用 sudo 启动
sudo node server.js

# 或使用 PM2
sudo pm2 start server.js --name taotech

# 或使用 setcap（一次性设置）
sudo setcap 'cap_net_bind_service=+ep' $(which node)
```

### 原因 5: 防火墙阻止

**症状**: 本地可以连接，外部无法连接

**解决**:
```bash
# 检查防火墙状态
sudo ufw status

# 开放端口 80
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 或临时关闭防火墙（不推荐）
sudo ufw disable
```

### 原因 6: 服务器配置错误

**症状**: 服务器启动但立即崩溃

**解决**:
```bash
# 检查语法错误
node -c server.js

# 检查依赖
npm list

# 重新安装依赖
npm install

# 查看详细错误
node server.js
```

### 原因 7: SSL 证书问题（如果使用 HTTPS）

**症状**: HTTPS 连接失败

**解决**:
```bash
# 检查证书路径
ls -la /etc/letsencrypt/live/yourdomain.com/

# 检查证书权限
sudo chmod 644 /etc/letsencrypt/live/yourdomain.com/fullchain.pem
sudo chmod 600 /etc/letsencrypt/live/yourdomain.com/privkey.pem

# 使用 HTTP 模式测试
export NODE_ENV=development
node server.js
```

## 🔄 重启服务

### 使用 PM2

```bash
# 停止
pm2 stop taotech

# 删除
pm2 delete taotech

# 重新启动
pm2 start server.js --name taotech

# 查看日志
pm2 logs taotech
```

### 使用 systemd

```bash
# 重启
sudo systemctl restart taotech

# 查看状态
sudo systemctl status taotech

# 查看日志
sudo journalctl -u taotech -f
```

### 直接运行

```bash
# 停止当前进程（Ctrl+C）

# 重新启动
cd /www/wwwroot/taotech.com.hk
node server.js
```

## 🧪 测试步骤

### 1. 测试服务器是否响应

```bash
# 本地测试
curl -v http://localhost:80

# 应该看到类似输出：
# * Connected to localhost (127.0.0.1) port 80
# < HTTP/1.1 200 OK
```

### 2. 测试 API 端点

```bash
# 测试表单提交端点
curl -X POST http://localhost:80/api/submit \
  -H "Content-Type: application/json" \
  -d '{
    "name": "测试",
    "email": "test@example.com",
    "institution": "测试",
    "service": "测试",
    "message": "测试"
  }'
```

### 3. 检查浏览器控制台

1. 打开浏览器开发者工具 (F12)
2. 切换到 "Network" 标签
3. 刷新页面
4. 查看请求状态和错误信息

## 📋 检查清单

- [ ] 服务器进程正在运行
- [ ] 端口 80 未被其他服务占用
- [ ] 有足够的权限绑定端口 80
- [ ] 防火墙允许端口 80
- [ ] 服务器日志没有错误
- [ ] 依赖包已正确安装
- [ ] 文件权限正确
- [ ] 本地可以连接 (curl localhost:80)

## 🚨 紧急修复

如果问题紧急，可以临时使用其他端口：

```bash
# 使用端口 8080（不需要 root 权限）
export PORT=8080
node server.js

# 然后通过 Nginx 反向代理到 8080
```

## 📞 获取帮助

如果问题仍然存在，请提供：

1. **服务器状态**: `pm2 status` 或 `systemctl status taotech`
2. **端口占用**: `sudo lsof -i :80`
3. **服务器日志**: `pm2 logs taotech --lines 100`
4. **错误信息**: 浏览器控制台和网络标签的完整错误
5. **系统信息**: `uname -a` 和 `node -v`

---

**提示**: 大多数情况下，重启服务器可以解决临时连接问题。

