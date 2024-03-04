#!/bin/bash

#pacman:
directories=xdg-user-dirs
bluetooth=bluez
audio=pipewire pipewire-audio pipewire-alsa pipewire-pulse wireplumber
editor=neovim
file_explorer=ranger
fonts=nerd-fonts
video_driver=xf86-video-amdgpu mesa
terminal=alacritty zsh tmux neofetch
wallpaper=nitrogen
image_editor=gimp

pacman() {
    sudo pacman -S $directories $bluetooth $audio $editor $file_explorer $fonts $video_driver $terminal $wallpaper $image_editor  --noconfirm --needed

    #Bluetooth setup
    sudo systemctl start bluetooth.service
    sudo systemctl enable bluetooth.service
    
    #Directory setup
    xdg-user-dirs-update

}



#aur:
browser=google-chrome

aur() {
    git clone https://aur.archlinux.org/yay.git
    #might change depending on if your making a yay directory
    cd yay
    makepkg -si

    yay -S $browser

}

#Download
pacman
aur
