# submissions.txt 文件问题排查指南

如果提交表单后 `submissions.txt` 文件为空或没有内容，请按照以下步骤排查。

## 🔍 问题诊断

### 步骤 1: 检查服务器日志

查看服务器控制台输出或日志文件，查找错误信息：

```bash
# 如果使用 PM2
pm2 logs taotech

# 如果使用 systemd
journalctl -u taotech -f

# 如果直接运行
# 查看控制台输出
```

### 步骤 2: 检查文件权限

最常见的问题是文件权限不足：

```bash
# 进入项目目录
cd /www/wwwroot/taotech.com.hk

# 检查文件权限
ls -la submissions.txt

# 设置正确的权限（可读写）
chmod 666 submissions.txt

# 如果文件不存在，创建它
touch submissions.txt
chmod 666 submissions.txt
```

### 步骤 3: 检查文件所有者

确保 Node.js 进程有权限写入文件：

```bash
# 查看文件所有者
ls -la submissions.txt

# 查看 Node.js 进程运行用户
ps aux | grep node

# 如果所有者不匹配，修改所有者
chown www:www submissions.txt
# 或
chown node:node submissions.txt
```

### 步骤 4: 检查目录权限

确保项目目录有写入权限：

```bash
# 检查目录权限
ls -ld /www/wwwroot/taotech.com.hk

# 设置目录权限
chmod 755 /www/wwwroot/taotech.com.hk
```

## 🛠️ 快速修复

### 方法 1: 使用修复脚本

```bash
cd /www/wwwroot/taotech.com.hk
./fix-submissions-permissions.sh
```

### 方法 2: 手动修复

```bash
cd /www/wwwroot/taotech.com.hk

# 1. 创建文件（如果不存在）
touch submissions.txt

# 2. 设置权限
chmod 666 submissions.txt

# 3. 设置所有者（根据实际运行用户调整）
chown www:www submissions.txt
# 或
chown $(whoami):$(whoami) submissions.txt

# 4. 添加文件头（如果文件为空）
cat > submissions.txt << 'EOF'
=== 臨床AI演示預約記錄 ===
此文件用於保存所有通過網站提交的臨床AI演示預約表單數據
每次提交都會以增量方式追加到此文件
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
```

## 🔎 常见问题

### 问题 1: 文件权限不足

**症状**: 服务器日志显示 "EACCES: permission denied"

**解决**:
```bash
chmod 666 submissions.txt
chown www:www submissions.txt
```

### 问题 2: 文件不存在

**症状**: 服务器日志显示 "ENOENT: no such file or directory"

**解决**:
```bash
touch submissions.txt
chmod 666 submissions.txt
```

### 问题 3: 目录权限不足

**症状**: 无法创建文件

**解决**:
```bash
chmod 755 /www/wwwroot/taotech.com.hk
```

### 问题 4: SELinux 阻止（CentOS/RHEL）

**症状**: 权限正确但仍无法写入

**解决**:
```bash
# 检查 SELinux 状态
getenforce

# 如果是 Enforcing，设置文件上下文
chcon -t httpd_sys_rw_content_t submissions.txt

# 或临时禁用 SELinux（不推荐）
setenforce 0
```

### 问题 5: 磁盘空间不足

**症状**: 写入失败，日志显示 "ENOSPC"

**解决**:
```bash
# 检查磁盘空间
df -h

# 清理空间或扩展磁盘
```

## 📝 验证修复

修复后，测试表单提交：

1. **提交测试表单**
2. **检查服务器日志**，应该看到：
   ```
   ✓ 提交已保存到 /path/to/submissions.txt
   ✓ 驗證成功：提交內容已寫入文件
   ```
3. **检查文件内容**：
   ```bash
   cat submissions.txt
   ```

## 🔄 重启服务器

修复权限后，重启服务器使更改生效：

```bash
# PM2
pm2 restart taotech

# systemd
sudo systemctl restart taotech

# 直接运行
# Ctrl+C 停止，然后重新运行 node server.js
```

## 📊 监控和调试

### 启用详细日志

服务器现在会输出详细的日志信息，包括：
- 文件路径
- 文件大小
- 写入验证
- 错误详情

### 测试写入权限

可以手动测试文件写入：

```bash
cd /www/wwwroot/taotech.com.hk
echo "测试内容" >> submissions.txt
cat submissions.txt
```

如果成功，说明权限正确。

## 🚨 紧急处理

如果问题持续存在，可以：

1. **检查服务器错误日志**
2. **验证 Node.js 版本**（需要 14.x 或更高）
3. **检查文件系统**（是否只读）
4. **查看系统日志**：
   ```bash
   dmesg | tail
   ```

## 📞 获取帮助

如果以上方法都无法解决问题，请提供：
1. 服务器日志输出
2. 文件权限信息（`ls -la submissions.txt`）
3. Node.js 进程运行用户（`ps aux | grep node`）
4. 系统信息（`uname -a`）

---

**提示**: 更新后的 `server.js` 包含了详细的错误日志，可以帮助快速定位问题。

