#!/usr/bin/env node

/**
 * 测试表单提交脚本
 * 用于验证服务器是否能正确处理表单提交并写入文件
 */

const http = require('http');

const testData = {
    name: '测试用户',
    email: 'test@example.com',
    institution: '测试医院',
    service: '数据层级 - UK Biobank数据处理',
    message: '这是一条测试消息，用于验证表单提交功能是否正常工作。'
};

const options = {
    hostname: 'localhost',
    port: 8080,
    path: '/api/submit',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(JSON.stringify(testData))
    }
};

console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('测试表单提交');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('');
console.log('测试数据:');
console.log(JSON.stringify(testData, null, 2));
console.log('');
console.log('正在发送请求...');

const req = http.request(options, (res) => {
    console.log(`状态码: ${res.statusCode}`);
    console.log(`响应头:`, res.headers);
    console.log('');

    let data = '';

    res.on('data', (chunk) => {
        data += chunk;
    });

    res.on('end', () => {
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('服务器响应:');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        try {
            const response = JSON.parse(data);
            console.log(JSON.stringify(response, null, 2));
            
            if (response.success) {
                console.log('');
                console.log('✅ 测试成功！');
                console.log('请检查:');
                console.log('  1. 服务器日志中是否有写入记录');
                console.log('  2. submissions.txt 文件是否包含测试数据');
            } else {
                console.log('');
                console.log('❌ 测试失败:', response.message);
            }
        } catch (e) {
            console.log('原始响应:', data);
            console.log('解析错误:', e.message);
        }
    });
});

req.on('error', (error) => {
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.error('❌ 请求错误:');
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.error(error.message);
    console.error('');
    console.error('请确保:');
    console.error('  1. 服务器正在运行 (node server.js)');
    console.error('  2. 端口号正确 (默认 8080)');
    console.error('  3. 服务器地址正确');
});

req.write(JSON.stringify(testData));
req.end();

