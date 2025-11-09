# Node.js 服务器后台运行指南

本指南介绍如何让 `node server.js` 在后台运行，即使关闭终端也能继续运行。

## 🚀 方法一：使用 PM2（推荐，生产环境）

PM2 是 Node.js 进程管理器，功能强大且易于使用。

### 安装 PM2

```bash
npm install -g pm2
```

### 启动服务器

```bash
# 进入项目目录
cd /www/wwwroot/taotech.com.hk

# 使用 PM2 启动
pm2 start server.js --name taotech
```

### 常用 PM2 命令

```bash
# 查看运行状态
pm2 status

# 查看日志
pm2 logs taotech

# 查看实时日志（最后 50 行）
pm2 logs taotech --lines 50

# 停止服务
pm2 stop taotech

# 重启服务
pm2 restart taotech

# 删除服务
pm2 delete taotech

# 查看详细信息
pm2 info taotech

# 监控（CPU、内存使用情况）
pm2 monit
```

### 设置开机自启

```bash
# 生成启动脚本
pm2 startup

# 保存当前进程列表
pm2 save
```

### 使用配置文件（推荐）

创建 `ecosystem.config.js`：

```javascript
module.exports = {
  apps: [{
    name: 'taotech',
    script: 'server.js',
    cwd: '/www/wwwroot/taotech.com.hk',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 8080
    },
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};
```

启动：
```bash
pm2 start ecosystem.config.js
```

## 🔧 方法二：使用 nohup

简单但功能有限，适合临时使用。

### 启动

```bash
cd /www/wwwroot/taotech.com.hk
nohup node server.js > server.log 2>&1 &
```

### 查看日志

```bash
tail -f server.log
```

### 停止服务

```bash
# 查找进程
ps aux | grep "node server.js"

# 停止进程（替换 PID 为实际进程 ID）
kill <PID>
```

## 🖥️ 方法三：使用 screen

适合需要交互式操作的场景。

### 安装 screen

```bash
# Ubuntu/Debian
sudo apt install screen

# CentOS/RHEL
sudo yum install screen
```

### 使用 screen

```bash
# 创建新的 screen 会话
screen -S taotech

# 在 screen 中启动服务器
cd /www/wwwroot/taotech.com.hk
node server.js

# 按 Ctrl+A 然后按 D 来分离会话（服务器继续运行）

# 重新连接会话
screen -r taotech

# 查看所有会话
screen -ls

# 终止会话
screen -X -S taotech quit
```

## 🔄 方法四：使用 tmux

类似 screen，但功能更强大。

### 安装 tmux

```bash
# Ubuntu/Debian
sudo apt install tmux

# CentOS/RHEL
sudo yum install tmux
```

### 使用 tmux

```bash
# 创建新的 tmux 会话
tmux new -s taotech

# 在 tmux 中启动服务器
cd /www/wwwroot/taotech.com.hk
node server.js

# 按 Ctrl+B 然后按 D 来分离会话

# 重新连接会话
tmux attach -t taotech

# 查看所有会话
tmux ls

# 终止会话
tmux kill-session -t taotech
```

## ⚙️ 方法五：使用 systemd（Linux 服务）

适合系统级服务管理。

### 创建服务文件

创建 `/etc/systemd/system/taotech.service`：

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
Environment=PORT=8080

# 日志
StandardOutput=journal
StandardError=journal
SyslogIdentifier=taotech

[Install]
WantedBy=multi-user.target
```

### 使用服务

```bash
# 重新加载 systemd
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start taotech

# 停止服务
sudo systemctl stop taotech

# 重启服务
sudo systemctl restart taotech

# 查看状态
sudo systemctl status taotech

# 设置开机自启
sudo systemctl enable taotech

# 查看日志
sudo journalctl -u taotech -f
```

### 修改服务文件后

```bash
sudo systemctl daemon-reload
sudo systemctl restart taotech
```

## 📊 方法对比

| 方法 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| **PM2** | 功能强大、自动重启、日志管理、监控 | 需要安装 | **生产环境推荐** |
| **nohup** | 简单、无需安装 | 功能有限、管理不便 | 临时测试 |
| **screen** | 可交互、简单 | 需要手动管理 | 开发调试 |
| **tmux** | 功能强大、可交互 | 需要学习 | 开发调试 |
| **systemd** | 系统级管理、开机自启 | 配置复杂 | 服务器部署 |

## 🎯 推荐方案

### 生产环境
**使用 PM2**：
```bash
npm install -g pm2
pm2 start server.js --name taotech
pm2 startup
pm2 save
```

### 开发环境
**使用 screen 或 tmux**：
```bash
screen -S taotech
node server.js
# Ctrl+A, D 分离
```

## 🔍 检查服务是否运行

```bash
# 检查端口
netstat -tlnp | grep 8080
# 或
lsof -i :8080

# 检查进程
ps aux | grep "node server.js"

# 测试连接
curl http://localhost:8080
```

## 🛠️ 故障排查

### 服务无法启动

```bash
# 检查 Node.js 版本
node -v

# 检查依赖
npm list

# 查看错误日志
pm2 logs taotech
# 或
journalctl -u taotech -n 50
```

### 端口被占用

```bash
# 查找占用端口的进程
lsof -i :8080

# 停止占用进程
kill <PID>
```

### 权限问题

```bash
# 检查文件权限
ls -la server.js

# 检查目录权限
ls -ld /www/wwwroot/taotech.com.hk
```

## 📝 快速参考

### PM2 快速命令

```bash
pm2 start server.js --name taotech    # 启动
pm2 stop taotech                      # 停止
pm2 restart taotech                   # 重启
pm2 logs taotech                      # 查看日志
pm2 status                            # 查看状态
pm2 delete taotech                    # 删除
```

### systemd 快速命令

```bash
sudo systemctl start taotech          # 启动
sudo systemctl stop taotech           # 停止
sudo systemctl restart taotech        # 重启
sudo systemctl status taotech         # 查看状态
sudo journalctl -u taotech -f         # 查看日志
```

---

**推荐**: 生产环境使用 **PM2**，它提供了最好的进程管理和监控功能。

