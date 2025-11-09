# 端口冲突修复指南

当遇到 `EADDRINUSE` 错误时，说明端口已被占用。

## 🔍 快速诊断

### 检查端口占用

```bash
# 检查 8080 端口
sudo lsof -i :8080

# 或使用 netstat
sudo netstat -tlnp | grep 8080

# 或使用 ss
sudo ss -tlnp | grep 8080
```

## 🛠️ 解决方案

### 方案 1: 停止占用进程（推荐）

#### 步骤 1: 查找占用进程

```bash
# 查看占用 8080 端口的进程
sudo lsof -i :8080
```

输出示例：
```
COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
node    12345 www    23u  IPv4  12345      0t0  TCP *:8080 (LISTEN)
```

#### 步骤 2: 停止进程

```bash
# 方法 1: 使用 PM2（如果使用 PM2）
pm2 delete taotech
pm2 delete all  # 删除所有 PM2 进程

# 方法 2: 使用 kill（替换 PID 为实际进程 ID）
kill <PID>
# 或强制停止
kill -9 <PID>

# 方法 3: 使用 pkill
pkill -f "node server.js"
```

#### 步骤 3: 等待端口释放

```bash
# 等待几秒
sleep 3

# 再次检查
sudo lsof -i :8080
```

#### 步骤 4: 重新启动

```bash
pm2 start server.js --name taotech
```

### 方案 2: 使用其他端口

如果无法停止占用进程，可以临时使用其他端口：

#### 方法 1: 使用环境变量

```bash
# 设置端口为 3000
export PORT=3000
pm2 start server.js --name taotech

# 或使用 PM2 环境变量
pm2 start server.js --name taotech --update-env -- PORT=3000
```

#### 方法 2: 修改 PM2 配置

编辑 `ecosystem.config.js`：

```javascript
env: {
  NODE_ENV: 'development',
  PORT: 3000  // 改为其他端口
}
```

然后：
```bash
pm2 start ecosystem.config.js
```

#### 方法 3: 修改 server.js

临时修改 `server.js` 中的默认端口：

```javascript
const PORT = process.env.PORT || 3000;  // 改为 3000
```

### 方案 3: 使用修复脚本

运行项目中的修复脚本：

```bash
./fix-port-conflict.sh
```

脚本会自动：
- 检查端口占用
- 识别占用进程
- 提供停止建议
- 清理 PM2 进程

## 🔄 完整清理和重启流程

### 步骤 1: 停止所有相关进程

```bash
# 停止 PM2 进程
pm2 stop taotech
pm2 delete taotech

# 或停止所有 PM2 进程
pm2 stop all
pm2 delete all

# 查找并停止其他 Node.js 进程
ps aux | grep "node server.js" | grep -v grep
# 如果找到进程，使用 kill <PID>
```

### 步骤 2: 确认端口已释放

```bash
# 检查端口
sudo lsof -i :8080

# 应该没有输出（端口已释放）
```

### 步骤 3: 等待几秒

```bash
sleep 3
```

### 步骤 4: 重新启动

```bash
# 使用 PM2
pm2 start server.js --name taotech

# 或直接运行（测试）
node server.js
```

## 🧪 验证

### 检查服务状态

```bash
# PM2 状态
pm2 status

# 检查端口
sudo lsof -i :8080

# 测试连接
curl http://localhost:8080
```

### 查看日志

```bash
# PM2 日志
pm2 logs taotech

# 查看错误日志
pm2 logs taotech --err
```

## 📋 常见场景

### 场景 1: PM2 进程未正确停止

**症状**: PM2 显示进程已停止，但端口仍被占用

**解决**:
```bash
pm2 delete taotech
pm2 kill  # 强制停止 PM2 守护进程
pm2 resurrect  # 如果需要恢复
```

### 场景 2: 多个 Node.js 实例运行

**症状**: 多个进程占用同一端口

**解决**:
```bash
# 查找所有 Node.js 进程
ps aux | grep node

# 停止所有相关进程
pkill -f "node server.js"
# 或
killall node  # 谨慎使用
```

### 场景 3: 之前的进程未清理

**症状**: 重启服务器后端口仍被占用

**解决**:
```bash
# 检查是否有残留进程
ps aux | grep node

# 清理所有 Node.js 进程
pkill node

# 清理 PM2
pm2 kill
```

## 🚨 紧急修复

如果问题紧急，快速切换到其他端口：

```bash
# 1. 停止当前 PM2 进程
pm2 delete taotech

# 2. 使用端口 3000 启动
PORT=3000 pm2 start server.js --name taotech

# 3. 更新 Nginx 配置（如果需要）
# 修改 proxy_pass 为 http://localhost:3000
sudo nano /etc/nginx/sites-available/taotech
sudo nginx -t
sudo systemctl reload nginx
```

## 📝 预防措施

1. **使用 PM2 管理**: 确保进程正确停止
2. **检查端口**: 启动前检查端口是否可用
3. **使用环境变量**: 便于切换端口
4. **监控日志**: 及时发现端口冲突

## 🔍 调试命令

```bash
# 查看所有监听端口
sudo netstat -tlnp

# 查看特定端口
sudo lsof -i :8080

# 查看进程树
pstree -p | grep node

# 查看 PM2 进程详情
pm2 describe taotech
```

---

**提示**: 大多数情况下，`pm2 delete taotech` 然后重新启动即可解决问题。

