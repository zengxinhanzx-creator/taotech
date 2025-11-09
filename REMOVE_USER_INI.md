# 删除 .user.ini 文件指南

`.user.ini` 文件通常是宝塔面板或其他服务器管理工具创建的，具有特殊权限，普通 `rm` 命令无法删除。

## 🔧 解决方法

### 方法 1: 使用 chattr 命令（推荐）

```bash
# 1. 移除文件的不可变属性
chattr -i .user.ini

# 2. 然后删除文件
rm .user.ini
```

如果提示权限不足，使用 sudo：

```bash
sudo chattr -i .user.ini
sudo rm .user.ini
```

### 方法 2: 使用宝塔面板删除

如果使用宝塔面板：

1. 登录宝塔面板
2. 进入文件管理
3. 找到 `.user.ini` 文件
4. 右键删除

### 方法 3: 直接修改权限

```bash
# 修改文件权限
chmod 644 .user.ini

# 然后删除
rm .user.ini
```

### 方法 4: 强制删除（如果以上方法都不行）

```bash
# 使用 find 命令删除
find . -name ".user.ini" -type f -exec rm -f {} \;

# 或使用 sudo
sudo find . -name ".user.ini" -type f -exec rm -f {} \;
```

## 📋 完整步骤

```bash
# 进入项目目录
cd /www/wwwroot/taotech.com.hk

# 检查文件是否存在
ls -la .user.ini

# 查看文件属性
lsattr .user.ini

# 移除不可变属性
sudo chattr -i .user.ini

# 删除文件
sudo rm .user.ini

# 验证已删除
ls -la .user.ini
```

## ⚠️ 注意事项

1. **备份**: 删除前可以备份文件内容（如果需要）
   ```bash
   cat .user.ini > .user.ini.backup
   ```

2. **权限**: 通常需要 root 或 sudo 权限

3. **影响**: 删除 `.user.ini` 不会影响 Node.js 应用，这个文件主要用于 PHP 配置

## 🔍 检查其他隐藏文件

```bash
# 查看所有隐藏文件
ls -la | grep "^\."

# 查看是否有其他 .user.ini 文件
find . -name ".user.ini" -type f
```

## 💡 预防措施

如果不想让宝塔面板创建 `.user.ini` 文件：

1. 在宝塔面板设置中禁用相关功能
2. 或定期清理这些文件

---

**提示**: 对于 Node.js 项目，`.user.ini` 文件不是必需的，可以安全删除。

