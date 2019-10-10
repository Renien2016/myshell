#!/bin/bash

openvpn_dir=/etc/openvpn
openvpn_port=1194


createVPNServer(){
read -p "Please enter your VPNServer IP: " OutsideIP
[[ -z `rpm -qa|grep docker` ]] && {
yum remove docker docker-client  docker-client-latest  docker-common   docker-latest  docker-latest-logrotate docker-logrotate  docker-engine -y
yum install -y yum-utils  device-mapper-persistent-data  lvm2
yum-config-manager  --add-repo  https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --enable docker-ce-nightly
yum install docker-ce docker-ce-cli containerd.io  -y
systemctl daemon-reload
systemctl start docker  || {
	echo "docker install fail"
	exit 1
	}
}

mkdir $openvpn_dir
docker run -v $openvpn_dir:/etc/openvpn --rm -it kylemanna/openvpn ovpn_genconfig -u tcp://$OutsideIP
docker run -v $openvpn_dir:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki
docker run --name openvpn -v $openvpn_dir:/etc/openvpn -d -p $openvpn_port:1194/tcp --cap-add=NET_ADMIN kylemanna/openvpn
}



deluser(){
read -p "Delete username: " DNAME
docker run -v $openvpn_dir:/etc/openvpn --rm -it kylemanna/openvpn easyrsa revoke $DNAME
docker run -v $openvpn_dir:/etc/openvpn --rm -it kylemanna/openvpn easyrsa gen-crl
docker run -v $openvpn_dir:/etc/openvpn --rm -it kylemanna/openvpn rm -f /etc/openvpn/pki/reqs/"$DNAME".req
docker run -v $openvpn_dir:/etc/openvpn --rm -it kylemanna/openvpn rm -f /etc/openvpn/pki/private/"$DNAME".key
docker run -v $openvpn_dir:/etc/openvpn --rm -it kylemanna/openvpn rm -f /etc/openvpn/pki/issued/"$DNAME".crt
docker restart openvpn
}



adduser(){
read -p "please your username: " NAME
[[ -d $openvpn_dir/conf ]] || mkdir $openvpn_dir/conf
docker run -v $openvpn_dir:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full $NAME nopass
docker run -v $openvpn_dir:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient $NAME > $openvpn_dir/conf/"$NAME".ovpn
docker restart openvpn
sz $openvpn_dir/conf/"$NAME".ovpn
}


main(){
while true
do
echo "+===================================================+"

echo "\t\t\tWellcome to use openvpn"
echo "1.创建Openvpn 服务"
echo "2.添加openvpn 用户"
echo "3.删除opepvpn 用户"
echo "4.退出"
echo "+===================================================+"
read -p "请选择您的功能(1/2/3/4)：" num
case $num in
1)
createVPNServer
;;
2)
adduser
;;
3)
deluser
;;
4)
exit 0
;;
*)
	echo "Usages:输入有误，请重新输入"
	clear
;;
esac

done
}

main

