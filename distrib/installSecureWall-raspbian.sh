#!/bin/bash
cat << "EOF"
                             ;\ 
                            |' \ 
         _                  ; : ; 
        / `-.              /: : | 
       |  ,-.`-.          ,': : | 
       \  :  `. `.       ,'-. : | 
        \ ;    ;  `-.__,'    `-.| 
         \ ;   ;  :::  ,::'`:.  `. 
          \ `-. :  `    :.    `.  \ 
           \   \    ,   ;   ,:    (\ 
            \   :., :.    ,'o)): ` `-. 
           ,/,' ;' ,::"'`.`---'   `.  `-._ 
         ,/  :  ; '"      `;'          ,--`. 
        ;/   :; ;             ,:'     (   ,:) 
          ,.,:.    ; ,:.,  ,-._ `.     \""'/ 
          '::'     `:'`  ,'(  \`._____.-'"' 
             ;,   ;  `.  `. `._`-.  \\ 
             ;:.  ;:       `-._`-.\  \`. 
              '`:. :        |' `. `\  ) \ 
      -hrr-      ` ;:       |    `--\__,' 
                   '`      ,' 
                        ,-' 

   
EOF

randomString=$(head /dev/urandom | tr -dc a-z0-9 | head -c 2 ; echo '')

NEW_HOSTNAME="securewall-$randomString"
echo "Updating hostname to $NEW_HOSTNAME"
sed -i "s/raspberrypi/$NEW_HOSTNAME/g" /etc/hosts
sed -i "s/raspberrypi/$NEW_HOSTNAME/g" /etc/hostname

apt install wget curl software-properties-common apt-transport-https -y

echo "Update root certificates"
update-ca-certificates

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C80E383C3DE9F082E01391A0366C67DE91CA5D5F
echo 'Acquire::Languages "none";' | sudo tee /etc/apt/apt.conf.d/99disable-translations
if cat /etc/apt/sources.list | grep "cisofy" ; then
     echo "cisofy Repo already exists"
else
	echo "Adding cisofy Repo"
	echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list
fi

curl -fsSL https://www.securitasmachina.com/SecuritasMachina.gpg.key | apt-key add -

if cat /etc/apt/sources.list | grep "securitasmachina" ; then
     echo "SecuritasMachina Repository already exists"
else
	echo "Adding SecuritasMachina Repository"
	distro=$(lsb_release -i | cut -f 2-)
	distro=${distro,,}
	
	release=$(lsb_release -cs)
	release=${release,,}
	
	arch=$(uname --m)
	arch=${arch,,}
	
	echo "deb [arch=$arch] https://updates.securitasmachina.com/repos/apt/$distro $release stable" >> /etc/apt/sources.list
fi

#read -p "Enable the deb-src line, then press enter"

apt-get update -y
#apt source openssl

echo "Update root certificates"
update-ca-certificates

echo "Install common tools for further installation"
cd /tmp
wget -q https://raw.githubusercontent.com/SecuritasMachina/SecuritasMachina-Distrib/master/distrib/raspbian/package.lst

apt-get install -y $(awk -F: '/^[^#]/ { print $1 }' package.lst) 
echo 'Installing Squid w/ SSL'

wget -q https://github.com/SecuritasMachina/SecuritasMachina-Distrib/raw/master/distrib/raspbian/squid3_4.6-1+deb10u1_all.deb
wget -q https://github.com/SecuritasMachina/SecuritasMachina-Distrib/raw/master/distrib/raspbian/squid_4.6-1+deb10u1_armhf.deb
wget -q https://github.com/SecuritasMachina/SecuritasMachina-Distrib/raw/master/distrib/raspbian/squid-cgi_4.6-1+deb10u1_armhf.deb
wget -q https://github.com/SecuritasMachina/SecuritasMachina-Distrib/raw/master/distrib/raspbian/squid-cgi-dbgsym_4.6-1+deb10u1_armhf.deb
wget -q https://github.com/SecuritasMachina/SecuritasMachina-Distrib/raw/master/distrib/raspbian/squidclient_4.6-1+deb10u1_armhf.deb
wget -q https://github.com/SecuritasMachina/SecuritasMachina-Distrib/raw/master/distrib/raspbian/squidclient-dbgsym_4.6-1+deb10u1_armhf.deb
wget -q https://github.com/SecuritasMachina/SecuritasMachina-Distrib/raw/master/distrib/raspbian/squid-common_4.6-1+deb10u1_all.deb
wget -q https://github.com/SecuritasMachina/SecuritasMachina-Distrib/raw/master/distrib/raspbian/squid-dbgsym_4.6-1+deb10u1_armhf.deb
wget -q https://github.com/SecuritasMachina/SecuritasMachina-Distrib/raw/master/distrib/raspbian/squid-purge_4.6-1+deb10u1_armhf.deb
wget -q https://github.com/SecuritasMachina/SecuritasMachina-Distrib/raw/master/distrib/raspbian/squid-purge-dbgsym_4.6-1+deb10u1_armhf.deb

apt -o Dpkg::Options::="--force-confnew" install ./*.deb -y --allow-downgrades
echo 'disable further updates'
apt-mark hold squid squid-common
echo 'Shutdown & Disable Apache2'
update-rc.d apache2 disable
service stop apache2

apt -o Dpkg::Options::="--force-confnew" install -y securitas-wall
apt -o Dpkg::Options::="--force-confnew" install -y securitas-wall-tomcat
apt -o Dpkg::Options::="--force-confnew" install -y securitas-wall-host

read -rsp $'Press any key to restart or CTRL-c to abort...note may take 10 minutes to load virus and malware definitions' -n1 key
shutdown -r now
 