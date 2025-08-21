# 📦 NAS Repository Installation

## 🔐 Add GPG Key
```bash
wget -qO - https://DOMAIN/KEY.gpg | sudo apt-key add -
```

## 📁 Add Repository
```bash
echo "deb [arch=amd64] https://DOMAIN/ stable main" | sudo tee /etc/apt/sources.list.d/nas-repo.list
```

## 🔄 Update & Install
```bash
sudo apt update
sudo apt install nas-panel nas-web
```

## 🔑 GPG Key ID: F5346BDE8A82F78F7BC8C4A5ADAC6735A74C7E45
