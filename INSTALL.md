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

## 🔑 GPG Key ID: 5A2B2531DC7C74E77E6BE0D093A5134947EABBDE
