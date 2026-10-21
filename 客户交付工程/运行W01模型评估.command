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

echo "FDE W01 Promptfoo模型评估（7场景）"
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
echo "评估会真实调用模型服务，产生相应费用；首次运行需下载课程指定Promptfoo。"
export PROMPTFOO_DISABLE_TELEMETRY=1
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
cd "$PROJECT_DIR" || exit 1
run_stamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="$PROJECT_DIR/evidence/w01/模型评估备份/$run_stamp"
mkdir -p "$backup_dir" || exit 1
cp -R "$PROJECT_DIR/artifacts/w01" "$backup_dir/artifacts-w01" || exit 1
cd "$PROJECT_DIR/evals" || exit 1
npx --yes promptfoo@0.122.2 eval --config promptfooconfig.yaml --no-cache --output ../artifacts/w01/promptfoo-results.json
eval_exit=$?
unset FDE_MODEL_KEY
cd "$PROJECT_DIR" || exit 1
if [[ "$eval_exit" -eq 0 ]]; then
  "$PYTHON_BIN" tools/finalize_evaluation.py
  eval_exit=$?
else
  echo "评估未全部通过或运行失败，保留报告与窗口输出，暂不收尾登记通过。"
fi
echo
if [[ "$eval_exit" -eq 0 ]]; then
  echo "模型评估及课程收尾完成，请交给Codex核对报告。fit-gap和立项报告仍待完成。"
else
  echo "评估尚需排查，退出码：$eval_exit。请把脱敏结果发给Codex。"
fi
read -r "?按回车关闭窗口。"
exit "$eval_exit"
