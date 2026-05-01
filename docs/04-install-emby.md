# 04. 安装 Emby Server

本章节用于在 VPS 上安装 Emby Server，并将 rclone 挂载目录添加为媒体库。

默认访问端口：

```text
8096
```

默认媒体目录：

```text
/opt/emby_data
```

---

## 一、安装前准备

推荐系统：

```text
Debian 11/12
Ubuntu 20.04+
```

安装前建议先更新系统：

```bash
apt update
apt upgrade -y
```

确认服务器时间正常：

```bash
timedatectl
```

如果时区不是中国时区，可以设置为：

```bash
timedatectl set-timezone Asia/Shanghai
```

---

## 二、下载 Emby Server 安装包

以下以 `4.8.10.0` 版本为例：

```bash
wget https://github.com/MediaBrowser/Emby.Releases/releases/download/4.8.10.0/emby-server-deb_4.8.10.0_amd64.deb
```

如果需要安装最新版，可以到官方发布页查看：

```text
https://github.com/MediaBrowser/Emby.Releases/releases
```

然后替换下载链接中的版本号。

---

## 三、安装 Emby

执行：

```bash
dpkg -i emby-server-deb_4.8.10.0_amd64.deb
```

如果提示依赖问题，执行：

```bash
apt -f install -y
```

然后再次确认服务状态：

```bash
systemctl status emby-server
```

---

## 四、启动并设置开机自启

启动 Emby：

```bash
systemctl start emby-server
```

设置开机自启：

```bash
systemctl enable emby-server
```

查看状态：

```bash
systemctl status emby-server --no-pager
```

如果显示：

```text
active running
```

说明 Emby 已正常运行。

---

## 五、访问 Emby

浏览器访问：

```text
http://YOUR_SERVER_IP:8096
```

首次打开会进入初始化向导。

初始化时需要设置：

```text
语言
管理员账号
媒体库
元数据语言
远程访问
```

---

## 六、添加媒体库

如果前面已经使用 rclone 挂载到：

```text
/opt/emby_data
```

则在 Emby 后台添加媒体库时选择：

```text
/opt/emby_data
```

也可以按分类添加：

```text
/opt/emby_data/电影
/opt/emby_data/电视剧
/opt/emby_data/动漫
/opt/emby_data/综艺
```

推荐媒体库类型：

```text
电影 -> Movies
电视剧 -> TV Shows
动漫 -> TV Shows 或 Mixed Content
音乐 -> Music
```

---

## 七、媒体库刮削建议

建议设置：

```text
首选元数据语言：Chinese 或 zh-CN
国家/地区：中国
```

常见元数据源：

```text
TheMovieDb
TheTVDB
AniDB
```

如果刮削慢，可以先小范围添加一个目录测试，确认没有问题后再添加完整媒体库。

---

## 八、确认 Emby 识别到的真实路径

后续配置 go-emby2openlist 时，需要知道 Emby 识别到的本地路径。

例如 Emby 里某个视频路径是：

```text
/opt/emby_data/1/电影/test.mkv
```

OpenList 里的路径是：

```text
/1/电影/test.mkv
```

那么 go-emby2openlist 中应该配置：

```yaml
path:
  emby2openlist:
    - /opt/emby_data/1:/1
```

路径映射错误会导致：

```text
无法播放
无法获取直链
302 不生效
提示文件不存在
```

---

## 九、防止 Emby 直接走 VPS 中转

安装 Emby 后，原始访问地址是：

```text
http://YOUR_SERVER_IP:8096
```

如果直接通过这个地址播放，视频数据可能会经过 VPS 中转。

部署 go-emby2openlist 后，建议通过代理地址访问，例如：

```text
http://YOUR_SERVER_IP:8095
```

或者你自定义的端口：

```text
http://YOUR_SERVER_IP:8097
```

这样播放时可以通过 302 跳转到网盘直链。

---

## 十、常用管理命令

启动 Emby：

```bash
systemctl start emby-server
```

停止 Emby：

```bash
systemctl stop emby-server
```

重启 Emby：

```bash
systemctl restart emby-server
```

查看状态：

```bash
systemctl status emby-server
```

查看日志：

```bash
journalctl -u emby-server -f
```

---

## 十一、卸载 Emby，可选

如果需要卸载：

```bash
systemctl stop emby-server
apt remove emby-server -y
```

如果要删除配置和数据，请谨慎执行：

```bash
apt purge emby-server -y
```

注意：删除配置前请确认是否需要备份 Emby 数据。

---

## 十二、备份 Emby 配置

Emby 的配置和数据库通常在：

```text
/var/lib/emby
```

备份命令示例：

```bash
systemctl stop emby-server
tar -czvf emby-backup.tar.gz /var/lib/emby
systemctl start emby-server
```

恢复时可以解压回原目录，但建议先停止 Emby 服务。

---

## 十三、防火墙端口

如果服务器开启了防火墙，需要放行 Emby 端口：

```bash
ufw allow 8096/tcp
```

如果使用 go-emby2openlist，也需要放行代理端口：

```bash
ufw allow 8095/tcp
```

或者你的自定义端口：

```bash
ufw allow 8097/tcp
```

查看防火墙状态：

```bash
ufw status
```

---

## 十四、常见问题

### 1. 无法访问 8096

检查服务状态：

```bash
systemctl status emby-server
```

检查端口监听：

```bash
ss -tulnp | grep 8096
```

检查防火墙：

```bash
ufw status
```

---

### 2. 媒体库为空

检查 rclone 挂载是否正常：

```bash
ls -la /opt/emby_data
```

检查 Emby 权限：

```bash
chmod -R 755 /opt/emby_data
```

---

### 3. 扫描媒体库很慢

可能原因：

```text
网盘文件数量过多
rclone 挂载响应慢
元数据刮削源访问慢
服务器配置较低
```

建议：

```text
先添加小目录测试
关闭不需要的元数据源
避免一次性扫描过大目录
确认 rclone 挂载稳定
```

---

### 4. 播放卡顿

如果通过 `8096` 原始端口播放，可能是 VPS 带宽不足。

建议：

```text
部署 go-emby2openlist
通过 302 代理端口访问
确认播放请求跳转到网盘直链
```

---

