#! /bin/bash
set -e -o pipefail
export LC_ALL=C

install_swarm_agent() {
  curl -fsSL https://swarmguard.io/install.sh | sh > /dev/null
  swarm up
}

install_media_server() {
   platform=$(uname -m)

  # make sure libcamera is at the right place
  if [ ! -f "/lib/${platform}-linux-gnu/libcamera.so.0.0" ] && compgen -G "/lib/${platform}-linux-gnu/libcamera.so.*" > /dev/null; then
    mapfile -t files < <(compgen -G "/lib/${platform}-linux-gnu/libcamera.so.*")
    ln -s "${files[-1]}" "/lib/${platform}-linux-gnu/libcamera.so.0.0"
  fi
  if [ ! -f "/lib/${platform}-linux-gnu/libcamera-base.so.0.0" ] && compgen -G "/lib/${platform}-linux-gnu/libcamera-base.so.*" > /dev/null; then
    mapfile -t files < <(compgen -G "/lib/${platform}-linux-gnu/libcamera-base.so.*")
    ln -s "${files[-1]}" "/lib/${platform}-linux-gnu/libcamera-base.so.0.0"
  fi

  if [ "$platform" == "aarch64"  ]; then
    platformName="arm64"
  elif [ "$platform" == "x86_64" ]; then
    platformName="amd64"
  else
    echo "unknown platform, can not install media_server"
    exit 42
  fi

  curl --user "$USERNAME:$TOKEN" "https://gitlab.ti.bfh.ch/api/v4/projects/38296/packages/generic/mediamtx/1.8.1/linux_${platformName}.tar.gz?select=package_file" -o mediamtx.tar.gz
  tar -xzf mediamtx.tar.gz

  # remove previous
  systemctl stop mediamtx.service 2>/dev/null || true
  systemctl disable mediamtx.service 2>/dev/null || true
  rm -f /etc/systemd/system/mediamtx.service
  rm -f /usr/local/bin/mediamtx
  rm -f /usr/local/etc/mediamtx.yml
  rm -f /usr/local/etc/server.key
  rm -f /usr/local/etc/server.crt

  # add new
  mv mediamtx /usr/local/bin/
  mv mediamtx.yml /usr/local/etc/
  mv server.key /usr/local/etc/
  mv server.crt /usr/local/etc/

  tee /etc/systemd/system/mediamtx.service >/dev/null << EOF
  [Unit]
  Wants=network.target
  [Service]
  ExecStart=/usr/local/bin/mediamtx /usr/local/etc/mediamtx.yml
  [Install]
  WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable mediamtx
  systemctl start mediamtx

  rm mediamtx.tar.gz
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
read -p "  Enter access token: " -r -s TOKEN

print "start installing"
echo ""

print "- ⟳ installing media-server"
install_media_server
print "- ✓ installing media-server" 1

print "- ⟳ installing swarm_agent"
install_swarm_agent
print "- ✓ installing swarm_agent" 1

print "finished installing"
