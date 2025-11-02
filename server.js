const express = require('express');
const fs = require('fs');
const path = require('path');
const bodyParser = require('body-parser');

const app = express();
const PORT = 8080;
const SUBMISSIONS_FILE = path.join(__dirname, 'submissions.txt');

// 中间件
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static(__dirname));

// 确保 submissions.txt 文件存在
if (!fs.existsSync(SUBMISSIONS_FILE)) {
    const header = '=== 臨床AI演示預約記錄 ===\n此文件用於保存所有通過網站提交的臨床AI演示預約表單數據\n每次提交都會以增量方式追加到此文件\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n';
    fs.writeFileSync(SUBMISSIONS_FILE, header, 'utf8');
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

        // 追加写入文件（增量保存）
        fs.appendFileSync(SUBMISSIONS_FILE, submission, 'utf8');
        
        console.log(`✓ 提交已保存到 ${SUBMISSIONS_FILE}`);
        console.log(`  提交者: ${name} (${email})`);

        res.json({ 
            success: true, 
            message: '臨床AI演示預約成功！我們的專家團隊將在24小時內與您聯繫，安排演示時間。' 
        });
    } catch (error) {
        console.error('保存提交時發生錯誤:', error);
        res.status(500).json({ 
            success: false, 
            message: '服務器錯誤，請稍後再試' 
        });
    }
});

// 启动服务器
app.listen(PORT, () => {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✓ 服務器運行在 http://localhost:${PORT}`);
    console.log(`✓ 表單提交將增量保存到: ${SUBMISSIONS_FILE}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
});

