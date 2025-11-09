const express = require('express');
const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');
const bodyParser = require('body-parser');

const app = express();
const HTTP_PORT = process.env.HTTP_PORT || 80;
const HTTPS_PORT = process.env.HTTPS_PORT || 443;
const PORT = process.env.PORT || 8080;
const SUBMISSIONS_FILE = path.join(__dirname, 'submissions.txt');

// SSL 证书路径（从环境变量或默认路径读取）
const DOMAIN = process.env.DOMAIN || 'yourdomain.com';
const SSL_CERT_PATH = process.env.SSL_CERT_PATH || `/etc/letsencrypt/live/${DOMAIN}/fullchain.pem`;
const SSL_KEY_PATH = process.env.SSL_KEY_PATH || `/etc/letsencrypt/live/${DOMAIN}/privkey.pem`;

// 检查 SSL 证书是否存在
const hasSSL = fs.existsSync(SSL_CERT_PATH) && fs.existsSync(SSL_KEY_PATH);

// 中间件
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static(__dirname));

// 确保 submissions.txt 文件存在
if (!fs.existsSync(SUBMISSIONS_FILE)) {
    const header = '=== 臨床AI演示預約記錄 ===\n此文件用於保存所有通過網站提交的臨床AI演示預約表單數據\n每次提交都會以增量方式追加到此文件\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n';
    try {
        fs.writeFileSync(SUBMISSIONS_FILE, header, 'utf8');
        console.log(`✓ 創建 submissions.txt 文件: ${SUBMISSIONS_FILE}`);
    } catch (error) {
        console.error(`❌ 無法創建 submissions.txt 文件: ${error.message}`);
    }
} else {
    console.log(`✓ submissions.txt 文件已存在: ${SUBMISSIONS_FILE}`);
}

// 检查文件权限
try {
    fs.accessSync(SUBMISSIONS_FILE, fs.constants.W_OK);
    console.log(`✓ submissions.txt 文件可寫入`);
} catch (error) {
    console.error(`⚠ submissions.txt 文件可能沒有寫入權限: ${error.message}`);
    console.error(`  請運行: chmod 666 ${SUBMISSIONS_FILE}`);
}

// 处理表单提交
app.post('/api/submit', (req, res) => {
    try {
        const { name, email, institution, service, message } = req.body;
        
        // 验证必填字段
        if (!name || !email || !institution || !service || !message) {
            return res.status(400).json({ 
                success: false, 
                message: '請填寫所有必填字段' 
            });
        }

        // 邮箱验证
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({ 
                success: false, 
                message: '請輸入有效的郵箱地址' 
            });
        }

        // 格式化提交内容
        const timestamp = new Date().toLocaleString('zh-HK', {
            timeZone: 'Asia/Hong_Kong',
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });

        const submission = `
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
提交時間: ${timestamp}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
姓名: ${name}
郵箱: ${email}
機構/醫院名稱: ${institution}
感興趣的服務: ${service}
具體需求和期望:
${message}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

`;

        console.log('收到新提交:', { name, email, institution, service });
        console.log(`  文件路徑: ${SUBMISSIONS_FILE}`);

        // 检查文件是否存在
        if (!fs.existsSync(SUBMISSIONS_FILE)) {
            console.warn(`⚠ submissions.txt 文件不存在，正在創建...`);
            const header = '=== 臨床AI演示預約記錄 ===\n此文件用於保存所有通過網站提交的臨床AI演示預約表單數據\n每次提交都會以增量方式追加到此文件\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n';
            fs.writeFileSync(SUBMISSIONS_FILE, header, 'utf8');
        }

        // 追加写入文件（增量保存）
        try {
            fs.appendFileSync(SUBMISSIONS_FILE, submission, 'utf8');
            console.log(`✓ 提交已保存到 ${SUBMISSIONS_FILE}`);
            console.log(`  提交者: ${name} (${email})`);
            
            // 验证文件是否真的写入了
            const fileStats = fs.statSync(SUBMISSIONS_FILE);
            console.log(`  文件大小: ${fileStats.size} 字節`);
            
            // 读取最后几行验证
            const fileContent = fs.readFileSync(SUBMISSIONS_FILE, 'utf8');
            if (fileContent.includes(name) && fileContent.includes(email)) {
                console.log(`✓ 驗證成功：提交內容已寫入文件`);
            } else {
                console.warn(`⚠ 警告：提交內容可能未正確寫入文件`);
            }
        } catch (writeError) {
            console.error(`❌ 寫入文件時發生錯誤:`, writeError);
            console.error(`  錯誤詳情: ${writeError.message}`);
            console.error(`  錯誤堆棧: ${writeError.stack}`);
            throw writeError; // 重新抛出错误以便被外层 catch 捕获
        }

        res.json({ 
            success: true, 
            message: '臨床AI演示預約成功！我們的專家團隊將在24小時內與您聯繫，安排演示時間。' 
        });
    } catch (error) {
        console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.error('❌ 保存提交時發生錯誤:');
        console.error(`  錯誤類型: ${error.name}`);
        console.error(`  錯誤消息: ${error.message}`);
        console.error(`  錯誤堆棧: ${error.stack}`);
        console.error(`  文件路徑: ${SUBMISSIONS_FILE}`);
        console.error(`  文件存在: ${fs.existsSync(SUBMISSIONS_FILE)}`);
        if (fs.existsSync(SUBMISSIONS_FILE)) {
            try {
                const stats = fs.statSync(SUBMISSIONS_FILE);
                console.error(`  文件大小: ${stats.size} 字節`);
                console.error(`  文件權限: ${stats.mode.toString(8)}`);
            } catch (statError) {
                console.error(`  無法獲取文件信息: ${statError.message}`);
            }
        }
        console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        
        res.status(500).json({ 
            success: false, 
            message: '服務器錯誤，請稍後再試。錯誤已記錄到服務器日誌。' 
        });
    }
});

// HTTP 到 HTTPS 重定向（仅在生产环境且有 SSL 时）
if (hasSSL && process.env.NODE_ENV === 'production') {
    const httpApp = express();
    httpApp.use((req, res) => {
        res.redirect(301, `https://${req.headers.host}${req.url}`);
    });
    http.createServer(httpApp).listen(HTTP_PORT, () => {
        console.log(`✓ HTTP 服務器運行在端口 ${HTTP_PORT}（重定向到 HTTPS）`);
    });
}

// 启动服务器
if (hasSSL) {
    // 使用 HTTPS
    const options = {
        cert: fs.readFileSync(SSL_CERT_PATH),
        key: fs.readFileSync(SSL_KEY_PATH)
    };
    
    https.createServer(options, app).listen(HTTPS_PORT, () => {
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log(`✓ HTTPS 服務器運行在 https://localhost:${HTTPS_PORT}`);
        console.log(`✓ SSL 證書: ${SSL_CERT_PATH}`);
        console.log(`✓ 表單提交將增量保存到: ${SUBMISSIONS_FILE}`);
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    });
} else {
    // 使用 HTTP（开发环境）
    app.listen(PORT, () => {
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log(`✓ 服務器運行在 http://localhost:${PORT}`);
        console.log(`⚠ SSL 證書未找到，使用 HTTP 模式`);
        console.log(`  證書路徑: ${SSL_CERT_PATH}`);
        console.log(`  如需啟用 HTTPS，請參考 HTTPS_SETUP.md`);
        console.log(`✓ 表單提交將增量保存到: ${SUBMISSIONS_FILE}`);
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    });
}

