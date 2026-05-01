# 03. rclone 挂载 OpenList
用于将 OpenList 或网盘 WebDAV 挂载到 VPS 本地目录，供 Emby 扫描媒体库使用。

在本教程中，默认挂载目录为：

```text
/opt/emby_data
```

Emby 后续添加媒体库时，也使用这个目录。

---

## 一、安装前说明

rclone 可以把远程存储挂载成本地目录。  
本项目中常见用途是：

```text
OpenList / 网盘文件 -> rclone 挂载 -> /opt/emby_data -> Emby 媒体库
```

播放链路大致为：

```text
Emby 扫描 /opt/emby_data
go-emby2openlist 根据路径映射找到 OpenList 中对应文件
客户端通过 302 跳转到网盘直链播放
```

注意：

- rclone 挂载主要用于给 Emby 扫描媒体库
- 真正播放时推荐通过 go-emby2openlist 走 302 直链
- 如果直接用 Emby 源端口播放，可能仍然会消耗 VPS 流量

---

## 二、安装 fuse3

Debian/Ubuntu 系统执行：

```bash
apt update
apt install fuse3 -y
```

如果没有安装 fuse3，后续挂载时可能会出现 `fusermount` 相关错误。

---

## 三、安装 rclone

执行官方安装命令：

```bash
curl https://rclone.org/install.sh | sudo bash
```

安装完成后查看版本：

```bash
rclone version
```

如果能正常输出版本号，说明安装成功。

---

## 四、创建挂载目录

创建 Emby 使用的本地媒体目录：

```bash
mkdir -p /opt/emby_data
```

设置基础权限：

```bash
chmod -R 755 /opt/emby_data
```

如果后续 Emby 读取失败，可以临时放宽权限排查：

```bash
chmod -R 777 /opt/emby_data
```

生产环境不建议长期使用 `777`，排查完成后应收紧权限。

---

## 五、配置 rclone 远程存储

执行：

```bash
rclone config
```

按照提示创建一个远程配置。

如果你是通过 OpenList 的 WebDAV 来挂载，可以大致选择：

```text
n) New remote
name> alist
Storage> webdav
url> http://YOUR_SERVER_IP:5244/dav
vendor> other
user> OpenList 用户名
pass> OpenList 密码
```

最终远程名称示例为：

```text
alist
```

之后可以用下面命令测试：

```bash
rclone lsd alist:
```

如果能列出目录，说明 rclone 远程配置成功。

---

## 六、挂载 OpenList 到本地目录

执行：

```bash
rclone mount alist:/ /opt/emby_data \
  --allow-other \
  --vfs-cache-mode writes \
  --daemon
```

参数说明：

```text
alist:/                  rclone 远程路径
/opt/emby_data           本地挂载目录
--allow-other            允许其他用户访问挂载目录
--vfs-cache-mode writes  写入时使用 VFS 缓存
--daemon                 后台运行
```

---

## 七、验证挂载是否成功

查看挂载目录：

```bash
ls -la /opt/emby_data
```

查看磁盘挂载：

```bash
df -h
```

或者：

```bash
mount | grep emby_data
```

如果可以看到 OpenList 或网盘中的目录，说明挂载成功。

---

## 八、卸载挂载目录

如果需要取消挂载：

```bash
fusermount3 -u /opt/emby_data
```

如果系统没有 `fusermount3`，可以尝试：

```bash
fusermount -u /opt/emby_data
```

或者：

```bash
umount /opt/emby_data
```

---

## 九、配置开机自动挂载，可选

如果希望 VPS 重启后自动挂载，推荐使用 systemd。

创建服务文件：

```bash
nano /etc/systemd/system/rclone-emby.service
```

写入以下内容：

```ini
[Unit]
Description=Rclone Mount for Emby
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/rclone mount alist:/ /opt/emby_data \
  --allow-other \
  --vfs-cache-mode writes \
  --dir-cache-time 12h \
  --poll-interval 15s \
  --umask 002 \
  --log-file /var/log/rclone-emby.log \
  --log-level INFO
ExecStop=/bin/fusermount3 -u /opt/emby_data
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

重载 systemd：

```bash
systemctl daemon-reload
```

启动服务：

```bash
systemctl start rclone-emby
```

设置开机自启：

```bash
systemctl enable rclone-emby
```

查看状态：

```bash
systemctl status rclone-emby
```

查看日志：

```bash
tail -f /var/log/rclone-emby.log
```

---

## 十、Emby 中如何使用

进入 Emby 后台：

```text
控制台 -> 媒体库 -> 新建媒体库
```

媒体库路径选择：

```text
/opt/emby_data
```

或者根据你的实际目录选择：

```text
/opt/emby_data/电影
/opt/emby_data/电视剧
/opt/emby_data/动漫
```

---

## 十一、和 go-emby2openlist 的路径映射关系

假设 rclone 挂载后，Emby 看到的视频路径是：

```text
/opt/emby_data/1/电影/test.mkv
```

OpenList 里的真实路径是：

```text
/1/电影/test.mkv
```

那么 `go-emby2openlist` 的配置应该写：

```yaml
path:
  emby2openlist:
    - /opt/emby_data/1:/1
```

如果你有多个根目录，可以写多个映射：

```yaml
path:
  emby2openlist:
    - /opt/emby_data/1:/1
    - /opt/emby_data/2:/2
    - /opt/emby_data/3:/3
```

---

## 十二、常见问题

### 1. 挂载时报 fusermount 错误

先确认安装了 fuse3：

```bash
apt install fuse3 -y
```

再检查命令是否存在：

```bash
which fusermount3
```

---

### 2. Emby 看不到文件

检查挂载目录：

```bash
ls -la /opt/emby_data
```

检查 Emby 是否有权限读取：

```bash
chmod -R 755 /opt/emby_data
```

如果仍然不行，可以临时测试：

```bash
chmod -R 777 /opt/emby_data
```

---

### 3. rclone 挂载断开

查看进程：

```bash
ps aux | grep rclone
```

如果使用 systemd，查看服务：

```bash
systemctl status rclone-emby
```

重启服务：

```bash
systemctl restart rclone-emby
```

---

### 4. 播放时 VPS 流量很高

如果你是通过 Emby 原始端口 `8096` 播放，数据可能仍然经过 VPS 中转。

建议通过 go-emby2openlist 代理端口访问，例如：

```text
http://YOUR_SERVER_IP:8095
```

或你自定义映射的端口：

```text
http://YOUR_SERVER_IP:8097
```

并确认浏览器开发者工具中出现了 `302` 或 `307` 跳转。

---

## 十三、安全提醒

不要把以下内容上传到 GitHub：

```text
rclone.conf
OpenList 用户名
OpenList 密码
OpenList Token
真实服务器 IP
网盘账号信息
```

公开仓库中建议只写：

```text
YOUR_SERVER_IP
YOUR_OPENLIST_USERNAME
YOUR_OPENLIST_PASSWORD
```
