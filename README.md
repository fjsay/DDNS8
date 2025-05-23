# 🛰️ Public Domain DDNS Script

一个轻量级、纯 Shell 的 DDNS 动态域名更新脚本，专为 [YouDDNS](https://9517.eu.org/) 平台设计，无需 Python 或其他依赖，适用于任意 Linux/Windows 系统。


---

# Windows
---
在public-domain-ddns-script/windows有两个文件夹，根据需求选择性下载（一个是v6一个是v4），然后完善其中的内容即可，要完善的内容只有一行。完善后直接运行即可。可根据需求添加到计划任务。
```bash
curl -s "https://9517.eu.org/api/ddnsapi.php?token=你的API令牌&domain=你的域名"
```
---
---

# Linux(飞牛，群晖，绿联，Ubuntu，Debian，CentOS，armbian，威联通，极空间等)
---

## ✅ 一键安装

```bash
git clone https://github.com/fjsay/YouDDNS.git
cd YouDDNS
chmod +x install.sh
sudo ./install.sh
```

---

## ⚙️ 配置参数

安装完成后，编辑配置文件（使用一键安装会让你填写，填写错误的可以编辑文本）：

```bash
sudo vim /etc/ddns/config.conf
```

将其中内容修改为你自己的参数：

```bash
DOMAIN=你的域名
TOKEN=API令牌
v46=你要使用ipv4还是ipv6，填写数字即可
```

这些值来自你在 https://9517.eu.org/user/profile.php 页面设置生成的参数。

---

## 🧪 手动运行（调试用）

```bash
ddns
```

日志默认输出至终端: `cat /var/log/ddns.log`。

---

## 🔁 启用自动更新（每分钟检测 IP）

安装时已经自动开启每分钟更新

> ✅ 脚本会自动缓存上一次 IP，仅在公网 IP 发生变化时才会调用接口，避免频繁请求。

---

## ❌ 卸载方法

如果你不再使用 DDNS 功能，可以使用以下命令进行卸载：

```bash
cd YouDDNS
chmod +x uninstall.sh
sudo ./uninstall.sh
```

---

## 📦 文件说明

| 文件名        | 说明                          |
|---------------|-------------------------------|
| `ddns.sh`     | 核心更新逻辑脚本              |
| `install.sh`  | 一键安装脚本（安装 + 配置）   |
| `README.md`   | 本说明文档                    |


## 💬 问题反馈

欢迎在 Gitee 提 Issue 交流问题和建议：https://github.com/fjsay/YouDDNS-/issues

---

