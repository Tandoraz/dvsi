#! /bin/bash
set -e -o pipefail
export LC_ALL=C

install_swarm_agent() {
  curl -fsSL https://swarmguard.io/install.sh | sh > /dev/null
  swarm up
}

install_media_server() {
  platform=$(uname -m)
  
  if [ "$platform" == "aarch64"  ]; then
    platformName="arm64"
  elif [ "$platform" == "x86_64" ]; then
    platformName="amd64"
  else
    echo "unknown platform, can not install media_server"
    exit 42
  fi

  if [ ! -f "/lib/${platform}-linux-gnu/libcamera.so.0.0" ] && compgen -G "/lib/${platform}-linux-gnu/libcamera.so.*" > /dev/null; then
      file=$(compgen -G "/lib/${platform}-linux-gnu/libcamera.so.*")
      ln -s "$file" "/lib/${platform}-linux-gnu/libcamera.so.0.0"
  fi
  if [ ! -f "/lib/${platform}-linux-gnu/libcamera-base.so.0.0" ] && compgen -G "/lib/${platform}-linux-gnu/libcamera-base.so.*" > /dev/null; then
        file=$(compgen -G "/lib/${platform}-linux-gnu/libcamera-base.so.*")
        ln -s "$file" "/lib/${platform}-linux-gnu/libcamera.so.0.0"
  fi

  curl --user "$USERNAME:$TOKEN" "https://gitlab.ti.bfh.ch/api/v4/projects/38296/packages/generic/mediamtx/1.8.1/linux_${platformName}.tar.gz?select=package_file" | tar -xzf

  sudo mv mediamtx /usr/local/bin/
  sudo mv mediamtx.yml /usr/local/etc/
  sudo mv server.key /usr/local/etc/
  sudo mv server.crt /usr/local/etc/

  sudo systemctl daemon-reload
  sudo systemctl enable mediamtx
  sudo systemctl start mediamtx
}

print_logo() {
  cat << EOF
      ____ _    _______ ____            ____           __        ____
     / __ \ |  / / ___//  _/           /  _/___  _____/ /_____ _/ / /__  _____
    / / / / | / /\__ \ / /   ______    / // __ \/ ___/ __/ __ \`/ / / _ \/ ___/
   / /_/ /| |/ /___/ // /   /_____/  _/ // / / (__  ) /_/ /_/ / / /  __/ /
  /_____/ |___//____/___/           /___/_/ /_/____/\__/\__,_/_/_/\___/_/
EOF
}

ALWAYS_PRINT=("")
print() {
  clear
  print_logo
  for i in ${!ALWAYS_PRINT[@]}; do
    printf "  %s\n" "${ALWAYS_PRINT[i]}"
  done
  if [[ -n $2 ]]; then
    ALWAYS_PRINT+=("$1")
  fi
  printf "\n"
  printf "  %s\n" "$1"
}

#
# ======== Starting Script ========
#

if [[ $UID != 0 ]]; then
  print "must be run as root"
  exit
fi

print ""
read -p "  Enter username: " -r USERNAME
read -p "  Enter access token: " -r TOKEN

print "start installing"
echo ""

print "- ⟳ installing media-server"
install_media_server
print "- ✓ installing media-server" 1

print "- ⟳ installing swarm_agent"
install_swarm_agent
print "- ✓ installing swarm_agent" 1

print "finished installing"
