# Arch Linux Install
PLEASE READ THE OFFICIAL ARCH LINUX INSTALLIATION GUIDE BEFORE YOU START. YOU SHOULD STILL KNOW HOW THIS SCRIPT WORKS.

This repository consist of just a simple script installing arch linux using the official arch linux installation guide. In the future I may add a feature to encrypt the drives; so unfortunatley for now its going to be the base install with no encryption.

Please feel free to change anything on these scripts and message me about any improvements you found. 

This script takes some inpiration form [tom5760's arch-install script](https://github.com/tom5760/arch-install/blob/master/README.md).
## Helpfull Documents
* [Official Arch Linux Installation Guide](https://wiki.archlinux.org/title/installation_guide)
* [List of TimeZones](timezones.txt)
* [List of Keymaps](keymaps.txt)
## Install Guide
1. Please ensure you have a wifi connection.
2. Copy the install script to the live image.
```
curl -OLS https://github.com/Ryachenn/arch-install/raw/main/base_install.sh
```
3. Make the install script executable.
```
chmod +x base_install.sh
```
4. Run the script.
```
./base_install.sh
```
