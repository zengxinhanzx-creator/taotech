# 默认路径和端口配置说明

## 端口配置

### 标准端口
- **HTTP**: 80 端口
- **HTTPS**: 443 端口（标准 HTTPS 端口，无需在 URL 中指定）
- **Node.js 应用**: 8080 端口（内部端口，通过 Nginx 反向代理）

### 端口说明
- HTTP (80) 自动重定向到 HTTPS (443)
- HTTPS 使用标准 443 端口，访问时无需指定端口号
- Node.js 应用运行在 8080 端口，仅用于内部通信

## 路径配置

### 宝塔面板环境（自动检测）

如果检测到 `/www/server/panel` 目录存在，脚本会自动使用宝塔面板路径：

#### Nginx 配置
- **站点配置文件**: `/www/server/panel/vhost/nginx/taotech.com.hk.conf`
- **Nginx 主配置**: `/www/server/nginx/conf/nginx.conf`
- **Nginx 命令**: `/www/server/nginx/sbin/nginx`
- **日志目录**: `/www/wwwlogs/`

#### SSL 证书（宝塔面板申请）
- **证书路径**: `/www/server/panel/vhost/cert/taotech.com.hk/fullchain.pem`
- **密钥路径**: `/www/server/panel/vhost/cert/taotech.com.hk/privkey.pem`

#### SSL 证书（Let's Encrypt）
- **证书路径**: `/etc/letsencrypt/live/taotech.com.hk/fullchain.pem`
- **密钥路径**: `/etc/letsencrypt/live/taotech.com.hk/privkey.pem`

#### 项目目录
- **默认目录**: `/www/wwwroot/taotech.com.hk`

### 标准 Nginx 环境

如果未检测到宝塔面板，使用标准 Nginx 路径：

#### Nginx 配置
- **站点配置**: `/etc/nginx/sites-available/taotech`
- **启用配置**: `/etc/nginx/sites-enabled/taotech` (符号链接)
- **Nginx 命令**: `nginx` (系统 PATH)

#### SSL 证书
- **证书路径**: `/etc/letsencrypt/live/taotech.com.hk/fullchain.pem`
- **密钥路径**: `/etc/letsencrypt/live/taotech.com.hk/privkey.pem`

## 证书检测优先级

脚本按以下顺序检测 SSL 证书：

1. **宝塔面板证书** (如果检测到宝塔面板)
   - `/www/server/panel/vhost/cert/taotech.com.hk/fullchain.pem`

2. **Let's Encrypt 证书**
   - `/etc/letsencrypt/live/taotech.com.hk/fullchain.pem`

3. **其他 Let's Encrypt 证书**
   - 自动扫描 `/etc/letsencrypt/live/*/` 目录

## 脚本自动检测

所有脚本（`start.sh`, `fix-https-443.sh`, `fix-site.sh`, `check-site.sh`）都会：

1. **自动检测环境**
   - 检查是否存在 `/www/server/panel` 目录
   - 如果存在，使用宝塔面板路径
   - 如果不存在，使用标准 Nginx 路径

2. **自动检测证书**
   - 优先使用宝塔面板证书
   - 其次使用 Let's Encrypt 证书
   - 自动选择可用的证书路径

3. **自动配置端口**
   - HTTP: 80 端口
   - HTTPS: 443 端口（标准端口，无需在 URL 中指定）

## 配置文件位置

### 宝塔面板
- 在宝塔面板中：**网站** → `taotech.com.hk` → **设置** → **配置文件**
- 配置文件路径：`/www/server/panel/vhost/nginx/taotech.com.hk.conf`

### 标准 Nginx
- 配置文件：`/etc/nginx/sites-available/taotech`
- 启用链接：`/etc/nginx/sites-enabled/taotech`

## 访问地址

配置完成后，访问地址：

- **HTTP**: `http://taotech.com.hk` (自动重定向到 HTTPS)
- **HTTPS**: `https://taotech.com.hk` (标准 443 端口，无需指定端口号)
- **本地测试**: `http://localhost:8080` (Node.js 应用直接访问)

## 注意事项

1. **端口 443 是标准 HTTPS 端口**
   - 浏览器默认使用 443 端口访问 HTTPS
   - 无需在 URL 中指定端口号
   - 例如：`https://taotech.com.hk` 而不是 `https://taotech.com.hk:443`

2. **宝塔面板环境**
   - 脚本会自动检测并使用宝塔面板路径
   - 无需手动修改配置
   - 建议在宝塔面板中管理站点配置

3. **证书路径**
   - 脚本会自动检测可用的证书
   - 优先使用宝塔面板证书
   - 如果宝塔证书不存在，使用 Let's Encrypt 证书

4. **防火墙/安全组**
   - 确保云服务器安全组开放 80 和 443 端口
   - 本地防火墙会自动配置（如果可能）

