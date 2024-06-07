#! /bin/bash
set -e -o pipefail
export LC_ALL=C

install_swarm_agent() {
  curl -fsSL https://swarmguard.io/install.sh | sh > /dev/null
  swarm up
}

install_dvsi_gateway() {
  create_cert
  docker pull registry.gitlab.ti.bfh.ch/burgt2/dvsi/gateway:latest
  docker run --name dvsi-gateway -d --network host --restart=always -v /etc/hosts:/etc/hosts -v ~/.cert:/app/cert -e DVSI_AUTH_REALM="$USERNAME" registry.gitlab.ti.bfh.ch/burgt2/dvsi/gateway:latest
}

create_cert() {
  working_dir=$(pwd)
  ip=$(curl ipinfo.io/ip)
  mkdir ~/.cert -p
  cd ~/.cert
  touch ssl.cnf
  echo "[req]
default_bits  = 2048
default_md = sha256
distinguished_name = req_distinguished_name
req_extensions = req_ext
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
countryName = CH
stateOrProvinceName = Bern
localityName = Bern
organizationName = dvsi
commonName = dvsi Self-signed certificate

[req_ext]
subjectAltName = @alt_names
[v3_req]
subjectAltName = @alt_names
[alt_names]
IP.1 = $ip" > ~/.cert/ssl.cnf

  openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout privkey.pem -out cert.pem -config ssl.cnf
  fingerprint=$(openssl x509 -in cert.pem -noout -fingerprint -sha256 | cut -d "=" -f2 | tr -d ':')
  cd "$working_dir"
}

show_setup_qr_code() {
  printf "{\"gateway\":\"%s\",\"realm\":\"%s\",\"fingerprint\":\"%s\"}" "$ip" "$USERNAME" "$fingerprint" | curl -F-=\<- qrenco.de > .dvsi_config
  cat .dvsi_config
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

docker login -u "$USERNAME" -p "$TOKEN" registry.gitlab.ti.bfh.ch

clear

print "start installing"

print "- ⟳ installing swarm-agent"
install_swarm_agent
print "- ✓ installing swarm-agent" 1

print "- ⟳ installing dvsi-gateway"
install_dvsi_gateway
print "- ✓ installing dvsi-gateway" 1

print ""
show_setup_qr_code

echo "finished installing"
