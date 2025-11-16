# 安装 Node.js 并启动网站

## 问题诊断
网站无法打开的原因是：**Node.js 未安装**

## 解决方案

### 方案 1：使用 Homebrew 安装（推荐）

1. **安装 Homebrew**（如果还没有安装）：
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **安装 Node.js**：
   ```bash
   brew install node
   ```

3. **验证安装**：
   ```bash
   node --version
   npm --version
   ```

4. **安装项目依赖**：
   ```bash
   cd /Users/hanzengxin/Desktop/TaoTech-Website
   npm install
   ```

5. **启动网站**：
   ```bash
   npm start
   ```
   或者直接运行：
   ```bash
   node server.js
   ```

6. **访问网站**：
   打开浏览器访问：`http://localhost:8080`

### 方案 2：从官网下载安装

1. 访问 Node.js 官网：https://nodejs.org/
2. 下载 macOS 安装包（推荐 LTS 版本）
3. 运行安装程序
4. 安装完成后，重新打开终端
5. 运行以下命令：
   ```bash
   cd /Users/hanzengxin/Desktop/TaoTech-Website
   npm install
   npm start
   ```

### 方案 3：使用 nvm（Node Version Manager）

1. **安装 nvm**：
   ```bash
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
   ```

2. **重新加载终端配置**：
   ```bash
   source ~/.zshrc
   ```

3. **安装 Node.js**：
   ```bash
   nvm install --lts
   nvm use --lts
   ```

4. **安装项目依赖并启动**：
   ```bash
   cd /Users/hanzengxin/Desktop/TaoTech-Website
   npm install
   npm start
   ```

## 快速启动脚本

安装 Node.js 后，可以使用以下命令快速启动：

```bash
cd /Users/hanzengxin/Desktop/TaoTech-Website
npm install  # 首次运行需要安装依赖
npm start    # 启动服务器
```

## 验证网站运行

启动后，你应该看到类似以下输出：
```
服务器运行在 http://0.0.0.0:8080
表單提交將保存到: /Users/hanzengxin/Desktop/TaoTech-Website/submissions.txt
```

然后在浏览器中访问：`http://localhost:8080`

## 停止服务器

在终端中按 `Ctrl + C` 停止服务器。

