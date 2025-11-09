#!/bin/bash

# 修复 submissions.txt 文件权限脚本

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "submissions.txt 文件权限修复工具"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SUBMISSIONS_FILE="$SCRIPT_DIR/submissions.txt"

echo "文件路径: $SUBMISSIONS_FILE"
echo ""

# 检查文件是否存在
if [ ! -f "$SUBMISSIONS_FILE" ]; then
    echo "⚠ submissions.txt 文件不存在，正在创建..."
    
    # 创建文件
    cat > "$SUBMISSIONS_FILE" << 'EOF'
=== 臨床AI演示預約記錄 ===
此文件用於保存所有通過網站提交的臨床AI演示預約表單數據
每次提交都會以增量方式追加到此文件
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
    echo "✓ 文件已创建"
else
    echo "✓ 文件已存在"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "设置文件权限..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 设置文件权限（可读写）
chmod 666 "$SUBMISSIONS_FILE" 2>/dev/null || {
    echo "⚠ 需要管理员权限设置文件权限"
    echo "请运行: sudo chmod 666 $SUBMISSIONS_FILE"
    echo "或: sudo chown www:www $SUBMISSIONS_FILE && sudo chmod 666 $SUBMISSIONS_FILE"
}

# 检查当前权限
if [ -f "$SUBMISSIONS_FILE" ]; then
    PERMS=$(stat -c "%a" "$SUBMISSIONS_FILE" 2>/dev/null || stat -f "%OLp" "$SUBMISSIONS_FILE" 2>/dev/null)
    echo "当前文件权限: $PERMS"
    
    # 检查是否可写
    if [ -w "$SUBMISSIONS_FILE" ]; then
        echo "✓ 文件可写入"
    else
        echo "❌ 文件不可写入"
        echo "请运行: sudo chmod 666 $SUBMISSIONS_FILE"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "检查文件内容..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f "$SUBMISSIONS_FILE" ]; then
    FILE_SIZE=$(stat -c "%s" "$SUBMISSIONS_FILE" 2>/dev/null || stat -f "%z" "$SUBMISSIONS_FILE" 2>/dev/null)
    echo "文件大小: $FILE_SIZE 字节"
    
    if [ "$FILE_SIZE" -eq 0 ]; then
        echo "⚠ 文件为空，正在添加文件头..."
        cat > "$SUBMISSIONS_FILE" << 'EOF'
=== 臨床AI演示預約記錄 ===
此文件用於保存所有通過網站提交的臨床AI演示預約表單數據
每次提交都會以增量方式追加到此文件
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
        echo "✓ 文件头已添加"
    else
        echo "✓ 文件有内容"
        echo ""
        echo "文件前几行:"
        head -5 "$SUBMISSIONS_FILE"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "如果问题仍然存在，请检查:"
echo "  1. Node.js 进程的运行用户"
echo "  2. 文件所在目录的权限"
echo "  3. 服务器日志中的错误信息"
echo ""
echo "查看服务器日志:"
echo "  pm2 logs taotech"
echo "  或"
echo "  journalctl -u taotech -f"
echo ""

