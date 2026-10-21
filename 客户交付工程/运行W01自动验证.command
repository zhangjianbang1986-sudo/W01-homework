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

echo "FDE W01 真实模型自动验证（11项）"
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
echo "接下来会调用你的模型服务，产生对应服务费用。"
echo "验证只操作独立教学数据；不会修改网页中的会员标签。"
echo
cd "$PROJECT_DIR" || exit 1
run_stamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="$PROJECT_DIR/evidence/w01/自动验证备份/$run_stamp"
mkdir -p "$backup_dir" || exit 1
cp -R "$PROJECT_DIR/artifacts/w01" "$backup_dir/artifacts-w01" || exit 1
echo "已有作业输出已备份。开始执行课程原版验证脚本……"
"$PYTHON_BIN" tools/verify_product.py --live --home "$PROJECT_DIR/.runtime/verification-$run_stamp"
verify_exit=$?
unset FDE_MODEL_KEY
echo
if [[ "$verify_exit" -eq 0 ]]; then
  echo "11项自动验证通过。评估项仍待单独运行Promptfoo；这不代表整份作业已完成。"
else
  echo "验证尚未全部通过，退出码：$verify_exit。请保留本窗口结果，交给Codex继续排查。"
fi
echo "作业输出目录：$PROJECT_DIR/artifacts/w01"
read -r "?按回车关闭窗口。"
exit "$verify_exit"
