# Emby + OpenList + go-emby2openlist 302 直连部署教程

本仓库用于记录一套基于 VPS 的影音直连播放部署方案，主要组合为：

```text
OpenList + rclone + Emby + go-emby2openlist
```

实现目标：

```text
网盘资源通过 OpenList 管理
rclone 将 OpenList/WebDAV 挂载到本地
Emby 扫描本地挂载目录生成媒体库
go-emby2openlist 将播放请求转换为网盘直链
客户端通过 302/307 跳转直接播放网盘资源
```

简单来说，就是尽量让视频播放不经过 VPS 中转，从而降低服务器带宽压力。

---

## 一、项目结构

```text
.
├── README.md
├── .gitignore
├── config
│   ├── config.example.yml
│   └── docker-compose.example.yml
├── docs
│   ├── 03-rclone-mount.md
│   ├── 04-install-emby.md
│   ├── 05-go-emby2openlist.md
│   └── 06-qbittorrent-path.md
└── scripts
    ├── fix-qb-path.sh
    ├── install-emby.sh
    └── install-rclone.sh
```

---

## 二、整体工作原理

传统播放链路：

```text
客户端 -> Emby -> rclone/cd2 挂载 -> OpenList -> 网盘
客户端 <- Emby <- rclone/cd2 挂载 <- OpenList <- 网盘
```

这种模式下，视频数据会经过 VPS 中转，播放速度受 VPS 上传带宽影响。

使用 go-emby2openlist 后：

```text
客户端 -> go-emby2openlist -> Emby
客户端 -> go-emby2openlist -> OpenList -> 网盘直链
客户端 -> 网盘直链直接播放
```

也就是说：

```text
Emby 负责媒体库和播放记录
OpenList 负责网盘文件管理和直链获取
go-emby2openlist 负责代理 Emby 并返回 302/307 跳转
客户端直接访问网盘直链播放
```

---

## 三、推荐部署环境

推荐系统：

```text
Debian 11/12
Ubuntu 20.04+
```

推荐准备：

```text
一台 VPS
Docker
Docker Compose
OpenList
Emby Server
rclone
go-emby2openlist
```

常用端口：

```text
OpenList:              5244
Emby Server:           8096
go-emby2openlist HTTP: 8095
go-emby2openlist HTTPS:8094
```

---

## 四、部署流程

建议按以下顺序部署：

```text
1. 安装 OpenList
2. 安装并配置 rclone
3. 安装 Emby Server
4. 部署 go-emby2openlist
5. 配置路径映射
6. 通过代理地址访问 Emby
7. 验证 302/307 是否生效
```

本仓库目前主要包含第 2 步之后的文档。

---

## 五、文档导航

### 1. rclone 挂载 OpenList

文档：

```text
docs/03-rclone-mount.md
```

用途：

```text
将 OpenList/WebDAV 挂载到 VPS 本地目录
供 Emby 扫描媒体库使用
```

默认挂载目录：

```text
/opt/emby_data
```

快速安装脚本：

```bash
sudo bash scripts/install-rclone.sh
```

---

### 2. 安装 Emby Server

文档：

```text
docs/04-install-emby.md
```

用途：

```text
安装 Emby Server
添加 /opt/emby_data 为媒体库
扫描网盘媒体资源
```

快速安装脚本：

```bash
sudo bash scripts/install-emby.sh
```

Emby 默认访问地址：

```text
http://YOUR_SERVER_IP:8096
```

---

### 3. 部署 go-emby2openlist

文档：

```text
docs/05-go-emby2openlist.md
```

用途：

```text
代理 Emby
对接 OpenList
将播放请求转换为网盘直链
实现 302/307 直连播放
```

默认代理地址：

```text
http://YOUR_SERVER_IP:8095
```

当前示例使用版本：

```text
ambitiousjun/go-emby2openlist:v2.7.0
```

---

### 4. qBittorrent 下载路径修复

文档：

```text
docs/06-qbittorrent-path.md
```

用途：

```text
解决 qBittorrent 下载路径
OpenList 数据路径
Emby 扫描路径
三者不一致的问题
```

路径修复脚本：

```bash
sudo bash scripts/fix-qb-path.sh
```

默认软链接关系：

```text
/opt/openlist/data -> /opt/1panel/apps/openlist/openlist/data
```

如果你的 OpenList 数据目录不同，请先修改脚本中的变量。

---

## 六、快速开始

### 1. 克隆本仓库

```bash
git clone https://github.com/YOUR_NAME/YOUR_REPO.git
cd YOUR_REPO
```

如果只是参考文档，也可以直接在 GitHub 页面查看 `docs` 目录。

---

### 2. 安装 rclone

```bash
sudo bash scripts/install-rclone.sh
```

然后配置 rclone：

```bash
rclone config
```

测试远程目录：

```bash
rclone lsd alist:
```

挂载到本地：

```bash
rclone mount alist:/ /opt/emby_data \
  --allow-other \
  --vfs-cache-mode writes \
  --daemon
```

---

### 3. 安装 Emby

```bash
sudo bash scripts/install-emby.sh
```

访问：

```text
http://YOUR_SERVER_IP:8096
```

然后在 Emby 中添加媒体库：

```text
/opt/emby_data
```

---

### 4. 准备 go-emby2openlist 配置

创建部署目录：

```bash
mkdir -p ~/emby-302
cd ~/emby-302
```

复制示例配置：

```bash
cp /path/to/this/repo/config/config.example.yml ./config.yml
cp /path/to/this/repo/config/docker-compose.example.yml ./docker-compose.yml
```

如果你是在仓库目录中操作，可以执行：

```bash
mkdir -p ~/emby-302
cp config/config.example.yml ~/emby-302/config.yml
cp config/docker-compose.example.yml ~/emby-302/docker-compose.yml
cd ~/emby-302
```

编辑配置：

```bash
nano config.yml
```

至少需要修改：

```text
YOUR_SERVER_IP
YOUR_OPENLIST_TOKEN
path.emby2openlist 路径映射
```

---

### 5. 启动 go-emby2openlist

```bash
docker compose up -d
```

如果你的系统使用旧版命令：

```bash
docker-compose up -d
```

查看日志：

```bash
docker logs -f go-emby2openlist -n 100
```

访问代理后的 Emby：

```text
http://YOUR_SERVER_IP:8095
```

---

## 七、路径映射示例

路径映射是整个方案中最容易出错的地方。

假设 Emby 看到的路径是：

```text
/opt/emby_data/1/电影/test.mkv
```

OpenList 中对应路径是：

```text
/1/电影/test.mkv
```

那么 go-emby2openlist 中应该配置：

```yaml
path:
  emby2openlist:
    - /opt/emby_data/1:/1
```

如果有多个目录：

```yaml
path:
  emby2openlist:
    - /opt/emby_data/1:/1
    - /opt/emby_data/2:/2
    - /opt/emby_data/3:/3
```

如果路径映射错误，常见现象是：

```text
播放失败
无法获取直链
提示文件不存在
302/307 不生效
```

---

## 八、验证 302/307 是否生效

1. 浏览器访问代理地址：

```text
http://YOUR_SERVER_IP:8095
```

2. 登录 Emby

3. 播放一个视频

4. 按 `F12` 打开开发者工具

5. 进入 `Network` 面板

6. 查看播放请求

如果看到：

```text
302
307
```

并且跳转地址变成网盘直链，说明配置成功。

---

## 九、常用命令

### 查看 Emby 状态

```bash
systemctl status emby-server
```

### 重启 Emby

```bash
systemctl restart emby-server
```

### 查看 Emby 日志

```bash
journalctl -u emby-server -f
```

### 查看 go-emby2openlist 容器

```bash
docker ps | grep go-emby2openlist
```

### 查看 go-emby2openlist 日志

```bash
docker logs -f go-emby2openlist -n 100
```

### 重启 go-emby2openlist

```bash
docker restart go-emby2openlist
```

### 查看 rclone 挂载

```bash
df -h
mount | grep emby_data
ls -la /opt/emby_data
```

---

## 十、脚本说明

### `scripts/install-rclone.sh`

功能：

```text
安装 fuse3
安装 rclone
创建 /opt/emby_data
设置基础权限
```

执行：

```bash
sudo bash scripts/install-rclone.sh
```

---

### `scripts/install-emby.sh`

功能：

```text
下载 Emby Server deb 安装包
安装 Emby
启动 Emby
设置开机自启
```

执行：

```bash
sudo bash scripts/install-emby.sh
```

默认安装版本：

```text
4.8.10.0
```

如果需要安装其他版本，可以修改脚本中的：

```bash
EMBY_VERSION="4.8.10.0"
```

---

### `scripts/fix-qb-path.sh`

功能：

```text
创建 /opt/openlist/data 软链接
指向 1Panel OpenList 真实数据目录
方便 qBittorrent 写入同一份数据
```

执行：

```bash
sudo bash scripts/fix-qb-path.sh
```

默认路径：

```text
OpenList 真实目录：
/opt/1panel/apps/openlist/openlist/data

qBittorrent 期望目录：
/opt/openlist/data
```

如果路径不同，请先修改脚本变量：

```bash
OPENLIST_REAL_PATH="/opt/1panel/apps/openlist/openlist/data"
QB_EXPECT_PATH="/opt/openlist/data"
```

---

## 十一、配置文件说明

### `config/config.example.yml`

go-emby2openlist 示例配置文件。

复制为：

```bash
config.yml
```

然后修改：

```text
Emby 地址
OpenList 地址
OpenList Token
路径映射
SSL 配置
缓存配置
```

不要把真实的 `config.yml` 提交到公开仓库。

---

### `config/docker-compose.example.yml`

go-emby2openlist Docker Compose 示例文件。

复制为：

```bash
docker-compose.yml
```

然后启动：

```bash
docker compose up -d
```

不要把包含敏感环境变量的真实 `docker-compose.yml` 提交到公开仓库。

---

## 十二、防火墙端口

如果服务器开启了防火墙，需要放行相关端口。

Emby：

```bash
ufw allow 8096/tcp
```

go-emby2openlist HTTP：

```bash
ufw allow 8095/tcp
```

go-emby2openlist HTTPS：

```bash
ufw allow 8094/tcp
```

OpenList：

```bash
ufw allow 5244/tcp
```

查看防火墙状态：

```bash
ufw status
```

---

## 十三、备份建议

建议定期备份以下内容：

```text
Emby 配置目录
OpenList 配置和数据目录
go-emby2openlist config.yml
rclone.conf
Docker Compose 文件
SSL 证书
```

常见路径：

```text
Emby:
/var/lib/emby

rclone:
/root/.config/rclone/rclone.conf

go-emby2openlist:
~/emby-302/config.yml

OpenList:
根据你的安装方式确定
```

备份 Emby 示例：

```bash
systemctl stop emby-server
tar -czvf emby-backup.tar.gz /var/lib/emby
systemctl start emby-server
```

---

## 十四、安全提醒

请不要将以下内容提交到 GitHub：

```text
真实服务器 IP
OpenList Token
OpenList 用户名
OpenList 密码
Emby 管理员账号
Emby 管理员密码
Emby API Key
rclone.conf
SSL 私钥
.env
真实 config.yml
```

公开文档中建议统一使用占位符：

```text
YOUR_SERVER_IP
YOUR_OPENLIST_TOKEN
YOUR_EMBY_USERNAME
YOUR_EMBY_PASSWORD
```

本仓库的 `.gitignore` 已经默认忽略部分敏感文件，但仍建议提交前手动检查。

---

## 十五、常见问题

### 1. 访问 Emby 8096 失败

检查服务：

```bash
systemctl status emby-server
```

检查端口：

```bash
ss -tulnp | grep 8096
```

检查防火墙：

```bash
ufw status
```

---

### 2. Emby 扫描不到媒体

检查 rclone 挂载：

```bash
ls -la /opt/emby_data
```

检查权限：

```bash
chmod -R 755 /opt/emby_data
```

必要时临时测试：

```bash
chmod -R 777 /opt/emby_data
```

---

### 3. go-emby2openlist 播放失败

优先检查：

```text
OpenList Token 是否正确
OpenList 地址是否能访问
Emby 地址是否能访问
path.emby2openlist 是否正确
媒体文件在 OpenList 中是否真实存在
```

查看日志：

```bash
docker logs -f go-emby2openlist -n 100
```

---

### 4. 播放没有走 302/307

确认你访问的是代理地址：

```text
http://YOUR_SERVER_IP:8095
```

而不是 Emby 原始地址：

```text
http://YOUR_SERVER_IP:8096
```

然后使用浏览器开发者工具查看 Network 请求。

---

### 5. VPS 流量仍然很高

可能原因：

```text
通过 8096 原始端口播放
字幕首次提取经过本地挂载
客户端没有使用直链地址
路径映射失败回源播放
```

建议：

```text
通过 8095 代理地址访问
确认 302/307 跳转存在
检查 go-emby2openlist 日志
检查路径映射
```

---

## 十六、相关项目

OpenList：

```text
https://github.com/OpenListTeam/OpenList
```

go-emby2openlist：

```text
https://github.com/AmbitiousJun/go-emby2openlist
```

rclone：

```text
https://rclone.org/
```

Emby：

```text
https://emby.media/
```

---

## 十七、免责声明

本仓库仅用于个人学习和部署记录。

请遵守：

```text
当地法律法规
网盘服务条款
软件授权协议
版权相关规定
```

请勿将本项目用于任何违法或侵权用途。
