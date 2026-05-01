# Emby + OpenList + 302 直连部署教程

本项目记录如何在 VPS 上通过 1Panel、OpenList、rclone、Emby 和 go-emby2openlist 搭建一个支持网盘媒体库和 302 直连播放的影音服务。

## 功能说明

- 使用 1Panel 管理 VPS 服务
- 使用 OpenList 管理网盘文件
- 使用 rclone 挂载 OpenList 到本地目录
- 使用 Emby 刮削和播放媒体
- 使用 go-emby2openlist 实现 302 直连播放
- 解决 qBittorrent 下载路径和 OpenList 数据目录不一致的问题

## 部署环境

推荐环境：

- Debian 11/12 或 Ubuntu 20.04+
- 1 核 1G 以上 VPS
- Docker
- 1Panel
- OpenList
- Emby Server
- rclone
- qBittorrent，可选

## 目录结构

```bash
.
├── docs/
├── config/
├── scripts/
└── README.md
