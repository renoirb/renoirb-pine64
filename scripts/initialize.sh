#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive
export LANG="en_US.UTF-8"
export LANGUAGE="en_US"
export LC_ALL="en_US.UTF-8"

UNAME=$(uname)
if [ "$UNAME" != "Linux" ]; then
  (>&2 echo "Not Linux. (Linux != $UNAME)")
  exit 1
fi

if test "$(id -g)" -ne "0"; then
  (>&2 echo "You must run this as root.")
  exit 1
fi

if test ! -f /usr/local/sbin/resize_rootfs.sh; then
  (>&2 echo "This script is designed to run on a Pine64 Linux image from longsleep and expects /usr/local/sbin/resize_rootfs.sh to exist.")
  exit 1
fi

sed -i '/^%sudo/ s/ALL$/NOPASSWD:ALL/' /etc/sudoers

locale-gen "${LANG}"
update-locale LANG=${LANG} LANGUAGE=${LANGUAGE} LC_ALL=${LANG}
locale

# In last 12 lines we have mention of xconsole.
# Hopefully they won't change from the bottom because we'll lose all logging
if grep -R 'xconsole' /etc/rsyslog.d/50-default.conf > /dev/null; then
  # Awesome sed http://stackoverflow.com/questions/13380607/how-to-use-sed-to-remove-the-last-n-lines-of-a-file#answer-13383331
  sed -i -e :a -e '$d;N;2,12ba' -e 'P;D' /etc/rsyslog.d/50-default.conf
fi

adduser picocluster
mkdir -p /home/picocluster/.ssh

usermod -aG sudo picocluster
chown -R picocluster:picocluster /home/picocluster/.ssh

if ! test -f /home/picocluster/.ssh/authorized_keys; then
(cat <<- _EOF_
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFj/NFhvDC8/jefyS1yjNtw+LV8buTsIE2zm55m9rDIv renoirb@Hairy.local
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3yWFgjwICPb8kQdkO8OX228tGnRLzCvEV74QccCIGwZ3KvXzN9RDRdUZ7fr5sGhwx5s7WQbXkLwOtAxyAUPB1K2DJnJiK/99n4lEjR3vUZN5p7ni7LsrwuoD0A7fF3PlBILYI294xaI/nikJFP14MKgX2TZcEBfY6bVeNmIuthlimKsfpIA2KtKm56zurMjVfjPCQYmcrThs0Wa4ArlAal8IlwPcLAJrjWaFfqjJlIA+PwclXj1xbRLhALkwNmFwkTsea1oT70ydFAeWH+Ui8+bTpjtEIthDVL1BkQ8mMhbrRXa/rVFU72ENc7iY2pknKSBA0hlRRumG8gYKAAhh1 hello@renoirboulanger.com
_EOF_
) >> /home/picocluster/.ssh/authorized_keys
    chown -R picocluster:picocluster /home/picocluster/.ssh
fi

sed -i '/ pine64$/d' /etc/hosts

echo "deb http://apt.armbian.com $(lsb_release -cs) main utils" | tee /etc/apt/sources.list.d/armbian.list
apt-key adv --keyserver keys.gnupg.net --recv-keys 0x93D6889F9F0E78D5

apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common htop unzip parted exfat-fuse exfat-utils sunxi-tools

#apt-get install -y build-essential
#apt-get install -y dnsutils

apt-get install -y parted
sh /usr/local/sbin/resize_rootfs.sh
partprobe

/usr/local/sbin/pine64_update_uboot.sh
/usr/local/sbin/pine64_update_kernel.sh

#
# Do the following from the first node (e.g. node0) as picocluster user:
#
#     export MAX=$(cat /etc/hosts|grep cluster_member|wc -l| awk '{zero_indexed =($1 - 1)}END{print zero_indexed}')
#     for((i=1;i<=$MAX;i+=1)); do /usr/bin/ssh-copy-id -i /home/picocluster/.ssh/id_rsa.pub picocluster@node${i}; done
#
# Eventually see how to differenciate if we are on first node and run the code above.
# If you have no keys, do:
#
#     /usr/bin/ssh-keygen -t rsa -P '' -f /home/picocluster/.ssh/id_rsa
#     sudo cat /home/picocluster/.ssh/id_rsa.pub >> /home/picocluster/.ssh/authorized_keys
#
