#!/bin/bash

set -e

# rclone 安装脚本
# 默认适配 Debian/Ubuntu
# 安装 fuse3 和 rclone，并创建 /opt/emby_data 目录

MOUNT_DIR="/opt/emby_data"

echo "========================================"
echo " rclone 安装脚本"
echo "========================================"
echo ""

if [ "$(id -u)" -ne 0 ]; then
  echo "错误：请使用 root 权限执行，例如："
  echo "sudo bash scripts/install-rclone.sh"
  exit 1
fi

echo "更新软件包索引..."
apt update

echo ""
echo "安装 fuse3、curl、ca-certificates..."
apt install -y fuse3 curl ca-certificates

echo ""
echo "安装 rclone..."
curl https://rclone.org/install.sh | sudo bash

echo ""
echo "创建 Emby 媒体挂载目录：${MOUNT_DIR}"
mkdir -p "${MOUNT_DIR}"

echo ""
echo "设置基础权限..."
chmod -R 755 "${MOUNT_DIR}"

echo ""
echo "查看 rclone 版本："
rclone version

echo ""
echo "========================================"
echo " rclone 安装完成"
echo "========================================"
echo ""
echo "下一步执行："
echo "rclone config"
echo ""
echo "配置完成后，可以用类似命令挂载："
echo "rclone mount alist:/ ${MOUNT_DIR} --allow-other --vfs-cache-mode writes --daemon"
echo ""
echo "验证挂载："
echo "ls -la ${MOUNT_DIR}"
