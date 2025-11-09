const path = require('path');

// 默认项目目录
const DEFAULT_DIR = '/www/wwwroot/taotech.com.hk';
const PROJECT_DIR = process.env.PROJECT_DIR || DEFAULT_DIR;

module.exports = {
  apps: [{
    name: 'taotech',
    script: path.join(PROJECT_DIR, 'server.js'),
    cwd: PROJECT_DIR,
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'development',
      PORT: 8080,
      PROJECT_DIR: PROJECT_DIR
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 8080,
      HTTP_PORT: 80,
      HTTPS_PORT: 443,
      PROJECT_DIR: PROJECT_DIR
    },
    error_file: path.join(PROJECT_DIR, 'logs/pm2-error.log'),
    out_file: path.join(PROJECT_DIR, 'logs/pm2-out.log'),
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    time: true
  }]
};

