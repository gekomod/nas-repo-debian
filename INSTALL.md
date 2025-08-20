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

## 🔑 GPG Key ID: 745D8D7B91E893A5FA79932C8A41E0033F753BB9
