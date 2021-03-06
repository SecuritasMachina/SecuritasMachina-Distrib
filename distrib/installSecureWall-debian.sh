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
     echo "SecuritasMachina Repo already exists"
else
	echo "Adding SecuritasMachina Repo"
	echo "deb https://updates.securitasmachina.com/repos/apt/debian/ buster stable" >> /etc/apt/sources.list
fi

#read -p "Enable the deb-src line, then press enter"

apt-get update -y
#apt source openssl

echo "Update root certificates"
update-ca-certificates

echo "Install common tools for further installation"
cd /tmp
wget -q https://raw.githubusercontent.com/ackdev/SecuritasMachina-Distrib/master/distrib/debian/package.lst

apt-get install -y $(awk -F: '/^[^#]/ { print $1 }' package.lst) 
echo 'Installing Squid w/ SSL'

wget -q https://github.com/ackdev/SecuritasMachina-Distrib/raw/master/distrib/debian/squid3_4.6-1+deb10u1_all.deb
wget -q https://github.com/ackdev/SecuritasMachina-Distrib/raw/master/distrib/debian/squid_4.6-1+deb10u1_armhf.deb
wget -q https://github.com/ackdev/SecuritasMachina-Distrib/raw/master/distrib/debian/squid-cgi_4.6-1+deb10u1_armhf.deb
wget -q https://github.com/ackdev/SecuritasMachina-Distrib/raw/master/distrib/debian/squid-cgi-dbgsym_4.6-1+deb10u1_armhf.deb
wget -q https://github.com/ackdev/SecuritasMachina-Distrib/raw/master/distrib/debian/squidclient_4.6-1+deb10u1_armhf.deb
wget -q https://github.com/ackdev/SecuritasMachina-Distrib/raw/master/distrib/debian/squidclient-dbgsym_4.6-1+deb10u1_armhf.deb
wget -q https://github.com/ackdev/SecuritasMachina-Distrib/raw/master/distrib/debian/squid-common_4.6-1+deb10u1_all.deb
wget -q https://github.com/ackdev/SecuritasMachina-Distrib/raw/master/distrib/debian/squid-dbgsym_4.6-1+deb10u1_armhf.deb
wget -q https://github.com/ackdev/SecuritasMachina-Distrib/raw/master/distrib/debian/squid-purge_4.6-1+deb10u1_armhf.deb
wget -q https://github.com/ackdev/SecuritasMachina-Distrib/raw/master/distrib/debian/squid-purge-dbgsym_4.6-1+deb10u1_armhf.deb

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

