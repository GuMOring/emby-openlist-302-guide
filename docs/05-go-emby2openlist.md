# 05. 使用 go-emby2openlist 实现 302 直连
go-emby2openlist 是一个使用 Go 编写的 Emby + OpenList 网盘直链反向代理服务，可以将 Emby 的播放请求转换为 OpenList 网盘直链，从而实现 302 跳转播放。
项目地址：
```text
https://github.com/AmbitiousJun/go-emby2openlist
```
## 一、工作原理
正常情况下，Emby 通过本地挂载路径读取网盘资源，数据链路大致是：
```text
客户端 -> Emby 服务器 -> rclone/cd2 挂载服务 -> OpenList -> 网盘
```
这种模式下，视频数据会经过 VPS 中转，播放速度会受到 VPS 上传带宽影响。
使用 go-emby2openlist 后，播放链路变为：
```text
客户端 -> go-emby2openlist -> Emby
客户端 -> go-emby2openlist -> OpenList -> 网盘直链
客户端 -> 网盘直链直接播放
```
也就是说，视频播放时尽量不再经过 VPS 中转，而是让客户端直接访问网盘直链。
## 二、前置条件
部署前需要准备好：
- 已安装 Emby Server
- 已安装 OpenList
- Emby 媒体库路径和 OpenList 路径可以对应
- 服务器已安装 Docker
- 服务器已安装 Docker Compose
- 已获取 OpenList Token
示例：
```text
Emby 地址：http://YOUR_SERVER_IP:8096
OpenList 地址：http://YOUR_SERVER_IP:5244
代理地址：http://YOUR_SERVER_IP:8095
```
注意：请不要把真实 IP、Token、密码提交到 GitHub。
---
## 三、创建部署目录
```bash
mkdir -p ~/emby-302
cd ~/emby-302
```
---
## 四、创建 config.yml 配置文件
创建配置文件：
```bash
nano config.yml
```
写入以下基础配置：
```yaml
# Emby 访问配置
emby:
  host: http://YOUR_SERVER_IP:8096
  mount-path: /opt/emby_data
  proxy-error-strategy: origin
  images-quality: 100
  download-strategy: direct
# OpenList 访问配置
openlist:
  host: http://YOUR_SERVER_IP:5244
  token: YOUR_OPENLIST_TOKEN
  # OpenList 本地目录树生成功能
  # 如果你已经使用 rclone/cd2 挂载，可以先保持关闭
  local-tree-gen:
    enable: false
    ffmpeg-enable: false
    virtual-containers: mp4,mkv
    strm-containers: ts
    music-containers: mp3,flac
    auto-remove-max-count: 6000
    refresh-interval: 60
    ignore-containers: jpg,jpeg,png,txt,nfo,md
    threads: 8
# 阿里云盘转码资源配置
# 如果不是阿里云盘，建议关闭
video-preview:
  enable: false
  containers:
    - mp4
    - mkv
  ignore-template-ids:
    - LD
    - SD
# 路径映射
path:
  emby2openlist:
    - /opt/emby_data/1:/1
    - /opt/emby_data/2:/2
    - /opt/emby_data/3:/3
    - /opt/emby_data/4:/4
    - /opt/emby_data/5:/5
    - /opt/emby_data/6:/6
    - /opt/emby_data/7:/7
    - /opt/emby_data/8:/8
    - /opt/emby_data/9:/9
    - /opt/emby_data/10:/10
# 缓存配置
cache:
  enable: true
  expired: 1d
# SSL 配置
ssl:
  enable: false
  single-port: false
  key: testssl.cn.key
  crt: testssl.cn.crt
# 日志配置
log:
  disable-color: false
```
需要修改的地方：
```text
YOUR_SERVER_IP
YOUR_OPENLIST_TOKEN
path.emby2openlist 路径映射
```
---
## 五、路径映射说明
路径映射是最关键的配置。
示例：
```yaml
path:
  emby2openlist:
    - /opt/emby_data/电影:/电影
```
含义：
```text
左边：Emby 里看到的本地路径
右边：OpenList 里的真实路径
```
例如：
Emby 中的媒体路径是：
```text
/opt/emby_data/1/电影/测试电影.mkv
```
OpenList 中的路径是：
```text
/1/电影/测试电影.mkv
```
那么映射应该写：
```yaml
path:
  emby2openlist:
    - /opt/emby_data/1:/1
```
如果播放时提示文件不存在、无法获取直链、302 不生效，优先检查这个路径映射。
---
## 六、创建 docker-compose.yml
在 `~/emby-302` 目录下创建：
```bash
nano docker-compose.yml
```
写入：
```yaml
version: "3.1"
services:
  go-emby2openlist:
    image: ambitiousjun/go-emby2openlist:v2.7.0
    container_name: go-emby2openlist
    restart: always
    environment:
      - TZ=Asia/Shanghai
      - GIN_MODE=release
      # 如果服务器需要代理访问外网，可以按需开启
      # - HTTP_PROXY=http://127.0.0.1:7890
      # - HTTPS_PROXY=http://127.0.0.1:7890
    volumes:
      - ./config.yml:/app/config.yml
      - ./ssl:/app/ssl
      - ./custom-js:/app/custom-js
      - ./custom-css:/app/custom-css
      - ./lib:/app/lib
      - ./openlist-local-tree:/app/openlist-local-tree
    ports:
      - 8095:8095
      - 8094:8094
```
端口说明：
```text
8095：http 访问端口
8094：https 访问端口
```
如果你想让外部访问端口变成 `8097`，可以改成：
```yaml
ports:
  - 8097:8095
  - 8094:8094
```
这样访问地址就是：
```text
http://YOUR_SERVER_IP:8097
```
---
## 七、启动服务
在 `~/emby-302` 目录下执行：
```bash
docker-compose up -d
```
如果你的系统使用的是新版 Docker Compose，也可以执行：
```bash
docker compose up -d
```
查看容器状态：
```bash
docker ps
```
查看日志：
```bash
docker logs -f go-emby2openlist -n 100
```
---
## 八、访问代理后的 Emby
原始 Emby 地址：
```text
http://YOUR_SERVER_IP:8096
```
go-emby2openlist 代理地址：
```text
http://YOUR_SERVER_IP:8095
```
如果你在 `docker-compose.yml` 中改成了：
```yaml
ports:
  - 8097:8095
```
那么代理地址就是：
```text
http://YOUR_SERVER_IP:8097
```
建议后续通过代理地址访问 Emby。
---
## 九、验证 302 是否生效
1. 浏览器访问 go-emby2openlist 代理地址
```text
http://YOUR_SERVER_IP:8095
```
2. 登录 Emby
3. 播放一个视频
4. 按 `F12` 打开浏览器开发者工具
5. 切换到 `Network` 面板
6. 查看播放请求
如果看到请求状态码为：
```text
302
```
或者：
```text
307
```
并且跳转地址变成网盘直链，说明 302 直连配置成功。
---
## 十、修改配置后重启
如果你修改了 `config.yml`，需要重启容器：
```bash
docker-compose restart
```
或者：
```bash
docker compose restart
```
也可以直接重启指定容器：
```bash
docker restart go-emby2openlist
```
---
## 十一、更新 go-emby2openlist
进入部署目录：
```bash
cd ~/emby-302
```
拉取新版镜像：
```bash
docker-compose pull
```
重建并启动：
```bash
docker-compose up -d
```
如果使用新版命令：
```bash
docker compose pull
docker compose up -d
```
清理旧镜像：
```bash
docker image prune -f
```
---
## 十二、SSL 使用说明
如果需要使用 HTTPS，需要准备证书文件和私钥文件。
目录结构示例：
```text
~/emby-302/
├── config.yml
├── docker-compose.yml
└── ssl/
    ├── example.crt
    └── example.key
```
然后在 `config.yml` 中修改：
```yaml
ssl:
  enable: true
  single-port: false
  key: example.key
  crt: example.crt
```
说明：
```text
容器内部 HTTP 端口固定为 8095
容器内部 HTTPS 端口固定为 8094
```
如果需要修改外部访问端口，只需要修改 `docker-compose.yml` 的端口映射。
---
## 十三、自定义 JS/CSS
go-emby2openlist 支持向 Emby Web 注入自定义 JS 和 CSS。
目录说明：
```text
custom-js/
custom-css/
```
使用方式：
- 将 `.js` 文件放入 `custom-js` 目录
- 将 `.css` 文件放入 `custom-css` 目录
- 重启容器生效
重启命令：
```bash
docker-compose restart
```
---
## 十四、OpenList 本地目录树生成
go-emby2openlist 支持扫描 OpenList 目录，并在本地生成目录树，供 Emby 扫描入库。
如果你已经使用 rclone 或 CloudDrive2 挂载，可以先不启用。
默认关闭：
```yaml
openlist:
  local-tree-gen:
    enable: false
```
如果需要开启传统 strm 模式，可以配置：
```yaml
openlist:
  local-tree-gen:
    enable: true
    strm-containers: mp4,mkv,mp3,flac
```
如果需要生成虚拟文件，可以配置：
```yaml
openlist:
  local-tree-gen:
    enable: true
    virtual-containers: mp4,mkv
```
如果需要用 ffmpeg 解析真实时长，可以配置：
```yaml
openlist:
  local-tree-gen:
    enable: true
    ffmpeg-enable: true
    virtual-containers: mp4,mkv
```
注意：
- 开启 ffmpeg 可能增加网盘风控风险
- 扫描速度会变慢
- 不建议新手一开始就开启
- 建议先使用 rclone/cd2 挂载跑通基础播放
---
## 十五、常见问题
### 1. 访问 8095 显示异常
检查容器是否启动：
```bash
docker ps
```
查看日志：
```bash
docker logs -f go-emby2openlist -n 100
```
检查端口是否被占用：
```bash
ss -tulnp | grep 8095
```
---
### 2. 播放没有 302
优先检查：
```text
1. OpenList Token 是否正确
2. OpenList 地址是否能访问
3. Emby 地址是否能访问
4. path.emby2openlist 路径映射是否正确
5. 媒体文件是否在 OpenList 中真实存在
```
---
### 3. 播放提示文件不存在
大概率是路径映射不正确。
例如 Emby 路径是：
```text
/opt/emby_data/1/电影/test.mkv
```
OpenList 路径是：
```text
/1/电影/test.mkv
```
则配置应该是：
```yaml
path:
  emby2openlist:
    - /opt/emby_data/1:/1
```
修改后重启：
```bash
docker restart go-emby2openlist
```
---
### 4. 字幕加载慢
部分字幕首次播放时，Emby 可能会调用 FFmpeg 从本地挂载文件中提取字幕。
这可能导致：
- 首次播放字幕加载慢
- 首次播放仍然消耗服务器流量
- 第三方播放器体验可能更好
---
### 5. 阿里云盘转码是否需要开启
如果你使用的是阿里云盘，可以按需开启：
```yaml
video-preview:
  enable: true
```
如果你不是阿里云盘，建议保持：
```yaml
video-preview:
  enable: false
```
---
