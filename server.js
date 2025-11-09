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

// SSL 证书路径
const DOMAIN = process.env.DOMAIN || 'yourdomain.com';
const SSL_CERT_PATH = process.env.SSL_CERT_PATH || `/etc/letsencrypt/live/${DOMAIN}/fullchain.pem`;
const SSL_KEY_PATH = process.env.SSL_KEY_PATH || `/etc/letsencrypt/live/${DOMAIN}/privkey.pem`;
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
    } catch (error) {
        console.error(`無法創建 submissions.txt: ${error.message}`);
    }
}

// 检查文件权限
try {
    fs.accessSync(SUBMISSIONS_FILE, fs.constants.W_OK);
} catch (error) {
    console.error(`submissions.txt 文件沒有寫入權限: ${error.message}`);
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

        // 检查文件是否存在
        if (!fs.existsSync(SUBMISSIONS_FILE)) {
            const header = '=== 臨床AI演示預約記錄 ===\n此文件用於保存所有通過網站提交的臨床AI演示預約表單數據\n每次提交都會以增量方式追加到此文件\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n';
            fs.writeFileSync(SUBMISSIONS_FILE, header, 'utf8');
        }

        // 追加写入文件
        try {
            fs.accessSync(SUBMISSIONS_FILE, fs.constants.W_OK);
            fs.appendFileSync(SUBMISSIONS_FILE, submission, 'utf8');
        } catch (writeError) {
            console.error(`寫入文件錯誤: ${writeError.message}`);
            throw writeError;
        }

        res.json({ 
            success: true, 
            message: '臨床AI演示預約成功！我們的專家團隊將在24小時內與您聯繫，安排演示時間。' 
        });
    } catch (error) {
        console.error('保存提交時發生錯誤:', error.message);
        res.status(500).json({ 
            success: false, 
            message: '服務器錯誤，請稍後再試' 
        });
    }
});

// HTTP 到 HTTPS 重定向
if (hasSSL && process.env.NODE_ENV === 'production') {
    const httpApp = express();
    httpApp.use((req, res) => {
        res.redirect(301, `https://${req.headers.host}${req.url}`);
    });
    http.createServer(httpApp).listen(HTTP_PORT, '0.0.0.0', () => {
        console.log(`HTTP 服務器運行在端口 ${HTTP_PORT}（重定向到 HTTPS）`);
    });
}

// 启动服务器
if (hasSSL) {
    const options = {
        cert: fs.readFileSync(SSL_CERT_PATH),
        key: fs.readFileSync(SSL_KEY_PATH)
    };
    
    https.createServer(options, app).listen(HTTPS_PORT, '0.0.0.0', () => {
        console.log(`HTTPS 服務器運行在 https://0.0.0.0:${HTTPS_PORT}`);
        console.log(`表單提交將保存到: ${SUBMISSIONS_FILE}`);
    });
} else {
    const isProduction = process.env.NODE_ENV === 'production';
    app.listen(PORT, '0.0.0.0', () => {
        console.log(`服務器運行在 http://0.0.0.0:${PORT}`);
        if (isProduction) {
            console.log(`SSL 證書未找到，使用 HTTP 模式`);
        }
        console.log(`表單提交將保存到: ${SUBMISSIONS_FILE}`);
    });
}
