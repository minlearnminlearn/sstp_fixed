#!/bin/bash

MYIP=$(wget -qO- icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";
NIC=$(ip -o $ANU -4 route show to default | awk '{print $5}');
source /etc/os-release
OS=$ID
ver=$VERSION_ID
if [[ $OS == 'ubuntu' ]]; then
if [[ "$ver" = "18.04" ]]; then
yoi=Ubuntu18
elif [[ "$ver" = "20.04" ]]; then
yoi=Ubuntu20
fi
elif [[ $OS == 'debian' ]]; then
if [[ "$ver" = "9" ]]; then
yoi=Debian9
elif [[ "$ver" = "10" ]]; then
yoi=Debian10
fi
fi

touch /root/log-install.txt
mkdir -p /home/sstp /var/lib/premium-script
touch /home/sstp/sstp_account
touch /var/lib/premium-script/data-user-sstp
#detail nama perusahaan
country=ID
state=Indonesia
locality=Jawa-Tengah
organization=Magelang
organizationalunit=www.vpninjector.com
commonname=$MYIP
email=admin@vpninjector

#install sstp
apt-get update
apt-get install -y ppp pppoe iptables iptables-persistent
apt-get install -y build-essential cmake gcc linux-headers-`uname -r` git libpcre2-dev libssl-dev liblua5.1-0-dev ppp

wget https://ghproxy.minlearn.org/api/https://github.com/accel-ppp/accel-ppp/archive/refs/heads/master.zip
unzip -o master.zip -d /opt;mv /opt/accel-ppp-master /opt/accel-ppp-code
rm -rf master.zip

mkdir -p /opt/accel-ppp-code/build
cd /opt/accel-ppp-code/build/
cmake -DBUILD_DRIVER=TRUE -DRADIUS=FALSE \
-DBUILD_IPOE_DRIVER=TRUE -DBUILD_VLAN_MON_DRIVER=TRUE -DCMAKE_INSTALL_PREFIX=/usr -DKDIR=/usr/src/linux-headers-`uname -r` -DLUA=TRUE -DCPACK_TYPE=$yoi ..
make
make install
#cpack -G DEB
#dpkg -i accel-ppp.deb

#mv /etc/accel-ppp.conf.dist /etc/accel-ppp.conf
wget -O /etc/accel-ppp.conf "https://ghproxy.minlearn.org/api/https://github.com/minlearnminlearn/sstp_fixed/raw/refs/heads/main/accel.conf"
sed -i $MYIP2 /etc/accel-ppp.conf
chmod +x /etc/accel-ppp.conf
#systemctl start accel-ppp
#systemctl enable accel-ppp
#gen cert sstp
cd /home/sstp
openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
openssl genrsa -out server.key 4096
openssl req -new -key server.key -out ia.csr \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
openssl x509 -req -days 3650 -in ia.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt
#cp /home/sstp/server.crt /home/vps/public_html/server.crt
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 444 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 444 -j ACCEPT
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save > /dev/null
netfilter-persistent reload > /dev/null

kill -9 `pidof accel-pppd`
accel-pppd -d -c /etc/accel-ppp.conf
kill -9 `pidof python3`
(cd /home/sstp;python3 -m http.server 81 &)

#input perintah sstp
wget -O /usr/bin/add-sstp https://ghproxy.minlearn.org/api/https://github.com/minlearnminlearn/sstp_fixed/raw/refs/heads/main/add-sstp.sh && chmod +x /usr/bin/add-sstp
wget -O /usr/bin/del-sstp https://ghproxy.minlearn.org/api/https://github.com/minlearnminlearn/sstp_fixed/raw/refs/heads/main/del-sstp.sh && chmod +x /usr/bin/del-sstp
wget -O /usr/bin/cek-sstp https://ghproxy.minlearn.org/api/https://github.com/minlearnminlearn/sstp_fixed/raw/refs/heads/main/cek-sstp.sh && chmod +x /usr/bin/cek-sstp
wget -O /usr/bin/renew-sstp https://ghproxy.minlearn.org/api/https://github.com/minlearnminlearn/sstp_fixed/raw/refs/heads/main/renew-sstp.sh && chmod +x /usr/bin/renew-sstp
rm -f /root/sstp.sh

