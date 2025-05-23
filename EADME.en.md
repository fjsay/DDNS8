
# 🛰️ Public Domain DDNS Script  

A lightweight, pure Shell DDNS (Dynamic Domain Name System) update script designed specifically for the [YouDDNS](https://9517.eu.org/) platform. It requires no Python or other dependencies and is compatible with any Linux system.  


---  

## ✅ One-Click Installation  

```bash  
git clone https://github.com/fjsay/YouDDNS.git  
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
```  

These values are generated in your profile settings on the [YouDDNS platform](https://9517.eu.org/user/profile.php).  


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
