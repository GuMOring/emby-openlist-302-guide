# 06. qBittorrent 下载路径配置

本章节用于解决 qBittorrent 下载路径和 OpenList 数据目录不一致的问题。

如果你使用 qBittorrent 下载资源，并希望下载完成后能被 OpenList 和 Emby 正确识别，就需要保证：

```text
qBittorrent 写入的目录
OpenList 实际管理的数据目录
Emby 扫描到的媒体目录
```

三者之间路径能够对应。

---

## 一、问题说明

如果 OpenList 是通过 1Panel 或 Docker 安装的，它在容器中的数据目录可能类似：

```text
/opt/openlist/data
```

但在宿主机上的真实目录可能是：

```text
/opt/1panel/apps/openlist/openlist/data
```

这时候，如果 qBittorrent 运行在宿主机上，而下载路径填写成：

```text
/opt/openlist/data
```

可能会出现：

```text
qBittorrent 下载完成
OpenList 看不到文件
Emby 扫描不到文件
路径映射对不上
```

解决方法是使用软链接，让 qBittorrent 写入的路径指向 OpenList 的真实数据目录。

---

## 二、确认 OpenList 真实数据目录

如果你是通过 1Panel 安装 OpenList，常见路径为：

```text
/opt/1panel/apps/openlist/openlist/data
```

可以执行：

```bash
ls -la /opt/1panel/apps/openlist/openlist/data
```

如果能看到 OpenList 的数据文件，说明路径正确。

如果路径不存在，可以用下面命令查找：

```bash
find /opt -type d -name "data" | grep -i openlist
```

或者：

```bash
find /opt/1panel -type d | grep -i openlist
```

---

## 三、推荐目录设计

本教程推荐将宿主机路径统一成：

```text
/opt/openlist/data
```

然后让它软链接到 OpenList 真实数据目录：

```text
/opt/openlist/data -> /opt/1panel/apps/openlist/openlist/data
```

这样 qBittorrent 只需要填写：

```text
/opt/openlist/data
```

OpenList 也能读取到同一份数据。

---

## 四、创建软链接

先创建父目录：

```bash
mkdir -p /opt/openlist
```

创建软链接：

```bash
ln -s /opt/1panel/apps/openlist/openlist/data /opt/openlist/data
```

查看结果：

```bash
ls -l /opt/openlist/data
```

如果看到类似：

```text
/opt/openlist/data -> /opt/1panel/apps/openlist/openlist/data
```

说明软链接创建成功。

---

## 五、设置权限

为了让 qBittorrent 能正常写入，可以先设置权限：

```bash
chmod -R 755 /opt/1panel/apps/openlist/openlist/data
```

如果 qBittorrent 写入失败，可以临时放宽权限测试：

```bash
chmod -R 777 /opt/1panel/apps/openlist/openlist/data
```

注意：

```text
777 只建议用于排查问题
生产环境建议根据实际用户和用户组收紧权限
```

---

## 六、qBittorrent 中填写下载路径

进入 qBittorrent Web UI：

```text
设置 -> 下载 -> 默认保存路径
```

填写：

```text
/opt/openlist/data
```

如果你想按分类保存，可以填写：

```text
/opt/openlist/data/电影
/opt/openlist/data/电视剧
/opt/openlist/data/动漫
```

---

## 七、OpenList 中检查文件

下载完成后，进入 OpenList 后台刷新目录，检查是否可以看到 qBittorrent 下载的文件。

如果看不到，可以检查：

```bash
ls -la /opt/openlist/data
```

以及真实目录：

```bash
ls -la /opt/1panel/apps/openlist/openlist/data
```

两边看到的内容应该一致。

---

## 八、和 Emby/rclone 的关系

如果你使用 rclone 将 OpenList 挂载到：

```text
/opt/emby_data
```

那么 Emby 中看到的路径可能是：

```text
/opt/emby_data/电影/test.mkv
```

OpenList 中的路径可能是：

```text
/电影/test.mkv
```

那么 go-emby2openlist 的路径映射可以写：

```yaml
path:
  emby2openlist:
    - /opt/emby_data:/ 
```

或者更明确地写：

```yaml
path:
  emby2openlist:
    - /opt/emby_data/电影:/电影
    - /opt/emby_data/电视剧:/电视剧
    - /opt/emby_data/动漫:/动漫
```

如果你的 OpenList 根目录下面有多个数字目录，例如：

```text
/1
/2
/3
```

则可以写：

```yaml
path:
  emby2openlist:
    - /opt/emby_data/1:/1
    - /opt/emby_data/2:/2
    - /opt/emby_data/3:/3
```

---

## 九、使用脚本自动修复

本仓库提供了一个脚本：

```text
scripts/fix-qb-path.sh
```

执行：

```bash
sudo bash scripts/fix-qb-path.sh
```

脚本默认使用以下路径：

```text
OpenList 真实目录：/opt/1panel/apps/openlist/openlist/data
qBittorrent 期望目录：/opt/openlist/data
```

如果你的路径不同，请先修改脚本中的变量。

---

## 十、常见问题

### 1. 创建软链接提示文件已存在

错误类似：

```text
ln: failed to create symbolic link '/opt/openlist/data': File exists
```

说明 `/opt/openlist/data` 已经存在。

先检查它是什么：

```bash
ls -la /opt/openlist/data
```

如果它是普通目录，并且里面有重要文件，不要直接删除。

如果确认没有重要数据，可以备份后处理：

```bash
mv /opt/openlist/data /opt/openlist/data.bak
ln -s /opt/1panel/apps/openlist/openlist/data /opt/openlist/data
```

---

### 2. qBittorrent 无法写入

检查权限：

```bash
ls -ld /opt/1panel/apps/openlist/openlist/data
```

临时测试：

```bash
chmod -R 777 /opt/1panel/apps/openlist/openlist/data
```

如果使用 Docker 版 qBittorrent，还需要确认容器挂载路径是否正确。

---

### 3. OpenList 看不到下载文件

检查真实目录是否有文件：

```bash
ls -la /opt/1panel/apps/openlist/openlist/data
```

检查软链接目录是否能看到同样内容：

```bash
ls -la /opt/openlist/data
```

如果真实目录有文件，但 OpenList 页面看不到，可以尝试刷新 OpenList 目录或重启 OpenList。

---

### 4. Emby 看不到下载文件

检查 rclone 挂载是否正常：

```bash
ls -la /opt/emby_data
```

然后在 Emby 后台重新扫描媒体库：

```text
控制台 -> 媒体库 -> 扫描媒体库文件
```

---

## 十一、安全提醒

执行路径修复前，请确认目录中是否有重要数据。

特别是以下命令要谨慎：

```bash
rm -rf
chmod -R 777
```

本教程推荐优先使用：

```bash
mv 原目录 原目录.bak
```

不要直接删除未知目录。
