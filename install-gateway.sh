#! /bin/bash
set -e -o pipefail
export LC_ALL=C

install_swarm_gateway() {
  curl -fsSL https://swarmguard.io/install-gateway.sh | sh

  swarm -q up
}

install_dvsi_gateway() {
  apiKey=$(docker exec swarmguard-l4gw bash -c 'echo "$API__SVCKEY"')
  echo "using apiKey: $apiKey"

  docker run --name dvsi-gateway -d --network host --restart=always -v /etc/hosts:/etc/hosts -e SWARMKEEPER_API_KEY="$apiKey" registry.gitlab.ti.bfh.ch/burgt2/dvsi/gateway:latest
}

show_setup_qr_code() {
  ip=$(curl ipinfo.io/ip)
  printf "{\"gateway\":\"%s\"}" "$ip" | curl -F-=\<- qrenco.de
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

docker login -u "$USERNAME" registry.gitlab.ti.bfh.ch

clear

print "start installing"

print "- ⟳ installing swarm-agent"
install_swarm_gateway
print "- ✓ installing swarm-agent" 1

print "- ⟳ installing dvsi-gateway"
install_dvsi_gateway
print "- ✓ installing dvsi-gateway" 1

print ""
show_setup_qr_code

echo "  finished installing"
