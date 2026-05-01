#!/bin/bash

set -e

# qBittorrent 路径修复脚本
# 作用：
# 将 /opt/openlist/data 软链接到 OpenList 的真实数据目录
#
# 默认适配 1Panel 安装的 OpenList：
# /opt/1panel/apps/openlist/openlist/data

OPENLIST_REAL_PATH="/opt/1panel/apps/openlist/openlist/data"
QB_EXPECT_PARENT="/opt/openlist"
QB_EXPECT_PATH="/opt/openlist/data"

echo "========================================"
echo " qBittorrent OpenList 路径修复脚本"
echo "========================================"
echo ""

echo "OpenList 真实目录：${OPENLIST_REAL_PATH}"
echo "qBittorrent 期望目录：${QB_EXPECT_PATH}"
echo ""

if [ "$(id -u)" -ne 0 ]; then
  echo "错误：请使用 root 权限执行，例如："
  echo "sudo bash scripts/fix-qb-path.sh"
  exit 1
fi

if [ ! -d "${OPENLIST_REAL_PATH}" ]; then
  echo "错误：OpenList 真实目录不存在：${OPENLIST_REAL_PATH}"
  echo ""
  echo "请先确认你的 OpenList 数据目录。"
  echo "可以尝试执行："
  echo "find /opt -type d -name data | grep -i openlist"
  exit 1
fi

echo "创建父目录：${QB_EXPECT_PARENT}"
mkdir -p "${QB_EXPECT_PARENT}"

if [ -L "${QB_EXPECT_PATH}" ]; then
  echo "检测到 ${QB_EXPECT_PATH} 已经是软链接。"
  echo "当前指向："
  readlink "${QB_EXPECT_PATH}"

  CURRENT_TARGET="$(readlink "${QB_EXPECT_PATH}")"

  if [ "${CURRENT_TARGET}" = "${OPENLIST_REAL_PATH}" ]; then
    echo "软链接已经正确，无需重复创建。"
  else
    echo "警告：当前软链接指向的不是目标目录。"
    echo "当前：${CURRENT_TARGET}"
    echo "目标：${OPENLIST_REAL_PATH}"
    echo ""
    echo "请手动确认后再修改。"
    exit 1
  fi
elif [ -e "${QB_EXPECT_PATH}" ]; then
  echo "错误：${QB_EXPECT_PATH} 已存在，但不是软链接。"
  echo ""
  echo "为避免误删数据，脚本不会自动删除该目录。"
  echo "请手动检查："
  echo "ls -la ${QB_EXPECT_PATH}"
  echo ""
  echo "如果确认没有重要数据，可以手动备份："
  echo "mv ${QB_EXPECT_PATH} ${QB_EXPECT_PATH}.bak"
  echo "然后重新执行本脚本。"
  exit 1
else
  echo "创建软链接："
  echo "${QB_EXPECT_PATH} -> ${OPENLIST_REAL_PATH}"
  ln -s "${OPENLIST_REAL_PATH}" "${QB_EXPECT_PATH}"
fi

echo ""
echo "设置基础权限..."
chmod -R 755 "${OPENLIST_REAL_PATH}"

echo ""
echo "验证软链接："
ls -l "${QB_EXPECT_PATH}"

echo ""
echo "验证目录内容："
ls -la "${QB_EXPECT_PATH}" | head

echo ""
echo "完成。"
echo ""
echo "现在可以在 qBittorrent 中将下载路径设置为："
echo "${QB_EXPECT_PATH}"
