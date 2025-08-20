# 📦 NAS Repository Installation

## 🔐 Add GPG Key
```bash
wget -qO - https://repo.naspanel.site/KEY.gpg | sudo apt-key add -
```

## 📁 Add Repository
```bash
echo "deb [arch=amd64] https://repo.naspanel.site/ stable main" | sudo tee /etc/apt/sources.list.d/nas-repo.list
```

## 🔄 Update & Install
```bash
sudo apt update
sudo apt install nas-panel nas-web
```

## 🔑 GPG Key ID: 
