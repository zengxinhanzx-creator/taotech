# TAO Technology Limited - 韜科技有限公司

**臨床醫學AI，精準醫療新未來**

韜科技是專注於臨床醫學AI技術的創新企業，提供三個層級的完整臨床AI服務體系，從醫學數據處理到臨床決策支持系統的端到端解決方案。

## 🚀 功能特點

### 三層級服務架構

#### 第一層級：數據層級
- UK Biobank生物樣本庫數據處理
- 醫學影像學數據處理（CT、MRI、X射線、超聲）
- 電子健康記錄(EHR)管理
- 臨床數據分析與統計
- 醫學數據可視化
- 臨床研究設計與執行

#### 第二層級：平台層級
- 高性能計算資源服務（GPU算力租賃）
- 臨床AI模型部署服務
- 大規模臨床數據挖掘

#### 第三層級：模型與應用層級
- 醫學自然語言處理大模型
- 臨床語音識別大模型
- 醫學影像診斷大模型
- 多模態臨床決策支持大模型
- 醫學AI大模型（臨床研究設計與異構數據分析）
- 臨床決策支持系統應用

## 🛠️ 技術棧

- **前端**: HTML5, CSS3, JavaScript (ES6+)
- **後端**: Node.js, Express.js
- **樣式**: 現代CSS（Glassmorphism、漸變、動畫）
- **字體**: Inter, JetBrains Mono
- **圖標**: Font Awesome 6.0
- **響應式設計**: 移動端、平板、桌面端全面適配

## 📋 項目結構

```
TaoTech-Website/
├── index.html              # 主頁面
├── styles.css              # 樣式表
├── script.js               # 前端邏輯
├── server.js               # 後端服務器
├── package.json            # 項目配置
├── ecosystem.config.js     # PM2 配置文件
├── favicon.svg             # 網站圖標
│
├── 部署腳本/
│   ├── start.sh            # 一鍵啟動腳本（支持診斷模式）
│   ├── stop.sh             # 停止服務腳本
│   └── setup-https.sh     # SSL 證書獲取腳本
│
├── Nginx 配置/
│   ├── nginx.conf.example          # 標準 Nginx 配置示例
│   └── taotech.com.hk.bt.conf      # 宝塔面板配置模板
│
├── 文檔/
│   ├── README.md           # 項目說明
│   ├── BT_PANEL_SETUP.md   # 宝塔面板設置指南
│   └── PATHS_AND_PORTS.md  # 路徑和端口配置說明
│
└── submissions.txt         # 表單提交記錄（自動生成）
```

## 🚀 快速開始

### 方法一：一鍵啟動（推薦）

使用一鍵啟動腳本自動配置和啟動所有服務：

```bash
# 啟動所有服務（PM2 + Nginx）
./start.sh

# 診斷模式（檢查服務狀態和配置）
./start.sh check
```

腳本會自動：
- 檢測環境（宝塔面板或標準 Nginx）
- 檢查 Node.js 和 npm
- 安裝項目依賴
- 安裝 PM2（如果未安裝）
- 清理舊進程
- 啟動 Node.js 應用
- 自動檢測 SSL 證書（宝塔面板或 Let's Encrypt）
- 配置 Nginx 反向代理（HTTP 80 → HTTPS 443）
- 檢查服務狀態

**診斷功能**：
- 運行 `./start.sh check` 可以診斷：
  - SSL 證書狀態
  - 端口監聽狀態（80, 443, 8080）
  - PM2 應用狀態
  - Nginx 配置狀態
  - 網站訪問測試

### 方法二：手動啟動

#### 安裝依賴

```bash
npm install
```

#### 啟動開發服務器

```bash
npm start
```

服務器將運行在 `http://localhost:8080`

**注意**: 
- Nginx 监听 80 端口（HTTP）和 443 端口（HTTPS）
- Node.js 运行在 8080 端口（内部端口）
- HTTP 自动重定向到 HTTPS
- 脚本会自动检测宝塔面板环境并使用相应配置
- 参考 `nginx.conf.example`（标准 Nginx）或 `taotech.com.hk.bt.conf`（宝塔面板）配置

### 停止服務

```bash
# 使用停止腳本
./stop.sh

# 或手動停止
pm2 stop taotech
pm2 delete taotech
```

### HTTPS 配置

獲取 SSL 證書：

```bash
# 使用 Let's Encrypt 獲取免費證書
./setup-https.sh
```

腳本會自動：
- 檢查 Certbot
- 獲取 SSL 證書
- 配置自動續期

**宝塔面板用戶**：可以在宝塔面板中直接申請 SSL 證書，腳本會自動檢測並使用。

### 表單提交

表單提交會自動保存到 `submissions.txt` 文件中，以增量方式追加。

## 📱 響應式設計

網站完全適配以下設備：
- 📱 手機（320px - 480px）
- 📱 大屏手機（481px - 768px）
- 📱 平板（769px - 1024px）
- 💻 桌面端（1025px+）

## 🎨 設計特色

- **科技感**: 玻璃態設計（Glassmorphism）
- **動畫效果**: 滾動觸發動畫、懸停效果
- **高清晰度圖片**: Unsplash高質量醫學AI主題圖片
- **漸變效果**: 動態漸變文字和背景
- **觸摸優化**: 移動端觸摸體驗優化

## 👥 團隊

- **A博士** - CEO & 醫學AI專家
- **B博士** - CTO & AI算法專家
- **C博士** - 基因組學AI總監
- **D博士** - 臨床AI研究總監
- **E博士** - 生物統計學與數據科學總監
- **F博士** - 藥物研發AI總監

## 📞 聯繫方式

- **總部地址**: ROOM 7F-12,7TH FLOOR,VALIANT INDUSTRIAL CENTRE, NOS. 2-12 AU PUI WAN STREET, FO TAN, N.T., HONG KONG
- **商務郵箱**: zengxin.hanzx@gmail.com
- **服務時間**: 週一至週五 9:00-18:00

## 📄 許可證

© 2024 TAO Technology Limited. 韜科技有限公司保留所有權利。

## 🌟 願景

成為全球臨床醫學AI領域全棧服務領導者，推動循證醫學變革，讓精準醫療與個性化治療方案普惠每一個患者。

---

**Built with ❤️ by TAO Technology Limited**
