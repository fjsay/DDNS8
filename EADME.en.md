
# 🛰️ Public Domain DDNS Script  

A lightweight, pure Shell DDNS (Dynamic Domain Name System) dynamic domain name update script specifically designed for the [DDNS8](https://ddns8.cn/) platform. It requires no Python or other dependencies and is suitable for any Linux/Windows system.  


---  

# Windows  
---  
In the `public-domain-ddns-script/windows` directory, there are two file. Download the appropriate one according to your needs (one for v6 and one for v4), then complete the content inside. Only one line needs to be completed. After completion, run it directly. You can add it to the scheduled tasks as needed.  
```bash  
curl -s "https://ddns8.cn/api/ddnsapi.php?token=Your API token&domain=Your domain"  
```  
---  

# Linux (Feiniu, Synology, Ugreen, Ubuntu, Debian, CentOS, Armbian, QNAP, ZKECO, etc.)  
---
## ✅ One-Click Installation  

```bash  
git clone https://github.com/fjsay/DDNS8.git  
cd YouDDNS  
chmod +x install.sh  
sudo ./install.sh  
```  


---  

## ⚙️ Configuration Parameters  

After installation, edit the configuration file (the one-click installation will prompt you to fill in the parameters; if filled incorrectly, you can edit the text later):  

```bash  
sudo vim /etc/ddns/config.conf  
```  

Modify the content with your own parameters:  

```bash  
DOMAIN=your-domain.com  
TOKEN=your-api-token
v46=the IP version you want to use (enter 4 or 6)  
```  

These values are generated in your profile settings on the [YouDDNS platform](https://ddns8.cn/user/profile.php).  


---  

## 🧪 Manual Execution (for Debugging)  

Run the script manually:  

```bash  
ddns  
```  

Logs are output to the terminal by default. View them with:  
```bash  
cat /var/log/ddns.log  
```  


---  

## 🔁 Enable Auto-Update (IP Check Every Minute)  

Automatic updates are enabled by default during installation.  

> ✅ The script automatically caches the last IP and only calls the API when the public IP changes, avoiding frequent requests.  


---  

## ❌ Uninstallation  

To uninstall the DDNS script, use the following commands:  

```bash  
cd YouDDNS  
chmod +x uninstall.sh  
sudo ./uninstall.sh  
```  


---  

## 📦 File Description  

| Filename       | Description                          |  
|----------------|--------------------------------------|  
| `ddns.sh`      | Core update logic script             |  
| `install.sh`   | One-click installation script (includes configuration) |  
| `README.md`    | Documentation (this file)            |  


---  

## 💬 Feedback  

Welcome to raise issues or suggestions on GitHub:  
https://github.com/fjsay/YouDDNS-/issues  

---
