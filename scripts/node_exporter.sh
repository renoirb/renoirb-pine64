#!/bin/bash

set -e

UNAME=$(uname)
if [ "$UNAME" != "Linux" ]; then
  (>&2 echo "Not Linux. (Linux != $UNAME)")
  exit 1
fi

if test "$(id -g)" -ne "0"; then
  (>&2 echo "You must run this as root.")
  exit 1
fi

PACKAGE_SERVICE_NAME="node-exporter"
PACKAGE_SERVICE_PORT="9100"
PACKAGE_NAME="node_exporter"

ARCH="arm64"
RELEASE="0.14.0"
ARCHIVE_EXT="tar.gz"

PACKAGE_REPO="https://github.com/prometheus/${PACKAGE_NAME}/releases/download/"
PACKAGE_URL=${PACKAGE_REPO}v${RELEASE}/${PACKAGE_NAME}-${RELEASE}.linux-${ARCH}.${ARCHIVE_EXT}
PACKAGE_UNPACK_PATH="/root/${PACKAGE_NAME}"
PACKAGE_BIN_DEST="/usr/local/bin/${PACKAGE_NAME}"

ARCHIVE_EXTRACT_CMD="tar xfz ${PACKAGE_UNPACK_PATH}/${PACKAGE_NAME}.${ARCHIVE_EXT} --strip-components=1 -C ${PACKAGE_UNPACK_PATH}"



if ! test -f "${PACKAGE_BIN_DEST}"; then
  echo "Package is NOT in ${PACKAGE_BIN_DEST}, we will install"
  mkdir -p "${PACKAGE_UNPACK_PATH}"
  curl -s -S -L "${PACKAGE_URL}" -o ${PACKAGE_UNPACK_PATH}/${PACKAGE_NAME}.${ARCHIVE_EXT}
  $(${ARCHIVE_EXTRACT_CMD})
  mv ${PACKAGE_UNPACK_PATH}/${PACKAGE_NAME} ${PACKAGE_BIN_DEST}
else
  echo "Package is already in ${PACKAGE_BIN_DEST}"
fi


(cat <<- _EOF_
[Unit]
Description=${PACKAGE_SERVICE_NAME} service
After=local-fs.target network-online.target network.target
Wants=local-fs.target network-online.target network.target

[Service]
User=nobody
Group=nogroup
Restart=on-failure
ExecStart=${PACKAGE_BIN_DEST}
Type=simple

[Install]
WantedBy=multi-user.target
_EOF_
) > /etc/systemd/system/${PACKAGE_SERVICE_NAME}.service


chown nobody:nogroup ${PACKAGE_BIN_DEST}
chown nobody:nogroup /etc/systemd/system/${PACKAGE_SERVICE_NAME}.service


if test -d "/etc/consul.d/"; then
  echo "{\"service\": {\"name\": \"${PACKAGE_SERVICE_NAME}\", \"port\": ${PACKAGE_SERVICE_PORT}}}" | sudo tee /etc/consul.d/${PACKAGE_SERVICE_NAME}.json
fi


echo 'Enabling service'
systemctl enable ${PACKAGE_SERVICE_NAME}.service
systemctl start ${PACKAGE_SERVICE_NAME}.service


echo 'Checing with SystemD if it is up'
systemctl status ${PACKAGE_SERVICE_NAME}
