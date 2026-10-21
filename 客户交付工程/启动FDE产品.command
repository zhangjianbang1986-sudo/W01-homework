#!/bin/zsh

set -u

PROJECT_DIR="${0:A:h}"
PYTHON_BIN="$PROJECT_DIR/.venv/bin/python"

if [[ ! -x "$PYTHON_BIN" ]]; then
  echo "未找到课程独立 Python 环境：$PYTHON_BIN"
  echo "请联系 Codex 重新完成依赖安装。"
  read -r "?按回车关闭窗口。"
  exit 1
fi

# 使用独立环境的可信 CA 证书，避免系统 Python 缺少证书链。
certificate_file="$("$PYTHON_BIN" -c 'import certifi; print(certifi.where())')" || exit 1
if [[ ! -f "$certificate_file" ]]; then
  echo "未找到 HTTPS 证书库，请联系 Codex 检查安装。"
  exit 1
fi
export SSL_CERT_FILE="$certificate_file"
unset certificate_file

echo "FDE W01 标准会员运营 Agent"
echo "密钥只用于本次本地进程，输入时不显示，也不会写入文件。"
echo

read -r "model_url?Chat Completions 完整地址 [https://api.deepseek.com/chat/completions]: "
model_url="${model_url:-https://api.deepseek.com/chat/completions}"

read -r "model_name?模型名称 [deepseek-flash]: "
model_name="${model_name:-deepseek-flash}"

read -r "model_profile?课程请求配置 [deepseek-low]: "
model_profile="${model_profile:-deepseek-low}"

read -rs "model_key?请输入 DeepSeek API Key（输入不显示）: "
echo

if [[ -z "$model_key" ]]; then
  echo "未输入 API Key，产品未启动。"
  read -r "?按回车关闭窗口。"
  exit 1
fi

export FDE_MODEL_URL="$model_url"
export FDE_MODEL_NAME="$model_name"
export FDE_MODEL_PROFILE="$model_profile"
export FDE_MODEL_KEY="$model_key"
unset model_key

echo
echo "启动后请在浏览器打开 http://127.0.0.1:8765"
echo "终端会同时显示随机分配的标签服务端口。按 Control+C 停止。"
echo

cd "$PROJECT_DIR" || exit 1
exec "$PYTHON_BIN" tools/product.py start --actions
