# 表单提交问题调试指南

如果提交表单后 `submissions.txt` 文件内容没有增加，请按照以下步骤排查。

## 🔍 步骤 1: 查看服务器日志

服务器现在会输出详细的调试信息。提交表单后，查看服务器控制台输出：

```bash
# 如果使用 PM2
pm2 logs taotech --lines 50

# 如果使用 systemd
journalctl -u taotech -f

# 如果直接运行
# 查看控制台输出
```

### 应该看到的日志

正常情况应该看到：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📥 收到表单提交请求
  方法: POST
  路径: /api/submit
  Content-Type: application/json
  请求体: { name: '...', email: '...', ... }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔵 进入 /api/submit 处理函数
  解析后的字段:
    name: ...
    email: ...
📝 準備寫入文件: /path/to/submissions.txt
✓ 文件可寫入
  寫入前文件大小: XXX 字節
✓ 文件寫入完成
  寫入後文件大小: YYY 字節
  增加大小: ZZZ 字節
✓ 驗證成功：提交內容已寫入文件
✅ 準備發送成功響應
✓ 響應已發送
```

## 🧪 步骤 2: 使用测试脚本

运行测试脚本验证服务器功能：

```bash
cd /www/wwwroot/taotech.com.hk
node test-submission.js
```

这会发送一条测试提交，并显示服务器响应。

## 🔎 步骤 3: 检查常见问题

### 问题 1: 请求没有到达服务器

**症状**: 日志中没有看到 "📥 收到表单提交请求"

**可能原因**:
- 前端请求路径错误
- 服务器没有运行
- 端口不匹配
- CORS 问题

**检查**:
```bash
# 检查服务器是否运行
ps aux | grep node

# 检查端口
netstat -tlnp | grep 80

# 检查浏览器控制台（F12）是否有错误
```

### 问题 2: 请求到达但验证失败

**症状**: 看到 "收到表单提交请求" 但返回 400 错误

**可能原因**:
- 字段为空
- 邮箱格式错误
- 字段名不匹配

**检查**: 查看日志中的 "解析后的字段" 部分

### 问题 3: 文件权限问题

**症状**: 看到 "❌ 文件不可寫入"

**解决方法**:
```bash
cd /www/wwwroot/taotech.com.hk
chmod 666 submissions.txt
chown www:www submissions.txt  # 根据实际用户调整
```

### 问题 4: 文件大小未增加

**症状**: 看到 "⚠ 警告：文件大小未增加"

**可能原因**:
- 文件系统只读
- 磁盘空间不足
- 权限问题

**检查**:
```bash
# 检查磁盘空间
df -h

# 检查文件系统
mount | grep /www

# 手动测试写入
echo "test" >> submissions.txt
```

## 🛠️ 步骤 4: 手动测试

### 测试 1: 使用 curl

```bash
curl -X POST http://localhost:80/api/submit \
  -H "Content-Type: application/json" \
  -d '{
    "name": "测试",
    "email": "test@example.com",
    "institution": "测试医院",
    "service": "数据层级",
    "message": "测试消息"
  }'
```

### 测试 2: 检查文件

```bash
# 查看文件内容
cat submissions.txt

# 查看文件大小
ls -lh submissions.txt

# 查看文件权限
ls -la submissions.txt
```

### 测试 3: 检查浏览器网络请求

1. 打开浏览器开发者工具 (F12)
2. 切换到 "Network" 标签
3. 提交表单
4. 查看 `/api/submit` 请求：
   - 状态码应该是 200
   - 响应应该包含 `"success": true`
   - 检查请求体是否正确

## 📋 调试检查清单

- [ ] 服务器正在运行
- [ ] 服务器日志显示收到请求
- [ ] 请求体包含所有必需字段
- [ ] 文件权限正确 (666)
- [ ] 文件所有者正确
- [ ] 磁盘空间充足
- [ ] 文件系统可写
- [ ] 浏览器控制台无错误
- [ ] 网络请求成功 (200)

## 🔄 重启服务器

修改代码后，记得重启服务器：

```bash
# PM2
pm2 restart taotech

# systemd
sudo systemctl restart taotech

# 直接运行
# Ctrl+C 停止，然后重新运行
node server.js
```

## 📞 获取帮助

如果问题仍然存在，请提供：

1. **服务器日志**（完整的请求处理日志）
2. **文件权限信息** (`ls -la submissions.txt`)
3. **测试脚本输出** (`node test-submission.js`)
4. **浏览器控制台错误**（如果有）
5. **网络请求详情**（开发者工具 Network 标签）

---

**提示**: 更新后的代码包含详细的调试日志，可以帮助快速定位问题。

