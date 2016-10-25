#!/bin/bash
# Copied and modified from
# https://github.com/deverton/terraform-aws-consul/blob/master/files/common/install-consul.sh
set -e

echo "consul-$(hostname)" > /etc/hostname
echo "127.0.0.1" $(cat /etc/hostname) >> /etc/hosts
hostname "$(cat /etc/hostname)"

export UI_DIR="/etc/consul/ui"
export JOIN_SERVICE_FILE="/etc/init/consul-join.conf"
export CONSUL_SERVICE_FILE="/etc/init/consul.conf"
export DATA_DIRECTORY="/etc/consul"
export HTTP_CLIENT_ADDR="0.0.0.0"
export ADVERTISE="$(ifconfig | grep eth0 -A1 | awk '/inet addr/{print substr($2,6)}')"
export SERVER_ARGS="-server -client=0.0.0.0 -advertise=${ADVERTISE} -data-dir=${DATA_DIRECTORY} -log-level=err -recursor=10.0.0.2 -syslog -ui-dir=${UI_DIR} -bind=${HTTP_CLIENT_ADDR} -datacenter=us-west-2 -bootstrap-expect=3 -ui"

echo "Installing Consul..."
pushd /tmp

# consul binary
wget -O consul.zip https://releases.hashicorp.com/consul/0.7.0/consul_0.7.0_linux_amd64.zip
unzip -d /usr/local/bin/ consul.zip
chmod +x /usr/local/bin/consul

# various directories
mkdir -p /etc/consul.d
mkdir -p /etc/consul
mkdir -p "${UI_DIR}"

# consul ui components
wget -O consul-ui.zip https://releases.hashicorp.com/consul/0.7.0/consul_0.7.0_web_ui.zip
unzip -d /etc/consul/ui consul-ui.zip
popd

# Setup the join address
echo "Configure IPs..."
export CONSUL_JOIN="consul1.domain.net consul2.domain.net consul3.domain.net"

# Configure the server
echo "Configure server..."
export CONSUL_FLAGS="${SERVER_ARGS}"

# Add "first start" join service
echo "Creating 'join' service..."
cat > "${JOIN_SERVICE_FILE}" <<EOF
description "Join the consul cluster"

start on started consul
stop on stopped consul

task

script

  # Keep trying to join until it succeeds
  set +e
  while :; do
    logger -t "consul-join" "Attempting join: ${CONSUL_JOIN}"
    /usr/local/bin/consul join \
      ${CONSUL_JOIN} \
      >> /var/log/consul-join.log 2>&1
    [ \$? -eq 0 ] && break
    sleep 5
  done

  logger -t "consul-join" "Join success!"
end script
EOF
chmod 0644 "${JOIN_SERVICE_FILE}"

# Add actual service
echo "Creating service..."
cat > "${CONSUL_SERVICE_FILE}" <<EOF
description "Consul agent"

start on runlevel [2345]
stop on runlevel [!2345]

respawn

script
  # Make sure to use all our CPUs, because Consul can block a scheduler thread
  export GOMAXPROCS=`nproc`

  exec /usr/local/bin/consul agent \
    -config-dir="/etc/consul.d" \
    ${CONSUL_FLAGS} \
    >> /var/log/consul.log 2>&1
end script
EOF
chmod 0644 "${CONSUL_SERVICE_FILE}"

# Start service
echo "Starting service..."
initctl start consul
