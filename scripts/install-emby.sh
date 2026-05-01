#!/bin/bash

set -e

# Emby Server 自动安装脚本
# 默认适配 Debian/Ubuntu amd64
# 默认安装版本：4.8.10.0

EMBY_VERSION="4.8.10.0"
DEB_FILE="emby-server-deb_${EMBY_VERSION}_amd64.deb"
DOWNLOAD_URL="https://github.com/MediaBrowser/Emby.Releases/releases/download/${EMBY_VERSION}/${DEB_FILE}"

echo "========================================"
echo " Emby Server 安装脚本"
echo "========================================"
echo ""

if [ "$(id -u)" -ne 0 ]; then
  echo "错误：请使用 root 权限执行，例如："
  echo "sudo bash scripts/install-emby.sh"
  exit 1
fi

echo "当前将安装 Emby Server 版本：${EMBY_VERSION}"
echo ""

echo "更新软件包索引..."
apt update

echo ""
echo "安装必要依赖..."
apt install -y wget curl ca-certificates

echo ""
echo "下载 Emby 安装包..."
echo "${DOWNLOAD_URL}"

if [ -f "${DEB_FILE}" ]; then
  echo "检测到安装包已存在，跳过下载：${DEB_FILE}"
else
  wget "${DOWNLOAD_URL}"
fi

echo ""
echo "安装 Emby..."
dpkg -i "${DEB_FILE}" || apt -f install -y

echo ""
echo "启动 Emby 服务..."
systemctl start emby-server

echo ""
echo "设置开机自启..."
systemctl enable emby-server

echo ""
echo "查看 Emby 状态..."
systemctl status emby-server --no-pager || true

echo ""
echo "========================================"
echo " Emby 安装完成"
echo "========================================"
echo ""
echo "请浏览器访问："
echo "http://YOUR_SERVER_IP:8096"
echo ""
echo "常用命令："
echo "systemctl status emby-server"
echo "systemctl restart emby-server"
echo "journalctl -u emby-server -f"
