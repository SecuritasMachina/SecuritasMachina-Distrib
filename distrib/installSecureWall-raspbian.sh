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

#Variables
pRamDir=/mnt/persist_ramdisk
ramDir=/mnt/ramdisk

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
	
	echo "deb https://updates.securitasmachina.com/repos/apt/$distro $release stable" >> /etc/apt/sources.list
fi


if cat /etc/fstab | grep "ramdisk" ; then
     echo "RAM disk already exists"
else
	echo "Adding RAM disk"
	mkdir -p /mnt/ramdisk
	cp -r /etc/fstab /etc/fstab.bak --backup=numbered
	#create fstab entries
	echo "tmpfs  /mnt/ramdisk  tmpfs  rw,size=1024M  0   0" >>/etc/fstab

	mount -t tmpfs -o size=1024m myramdisk /mnt/ramdisk
#setup sync service
cat > /lib/systemd/system/ramdisk-sync.service <<'endmsg1'
[Unit]
Before=umount.target

[Service]
Type=oneshot
User=root
ExecStartPre=/bin/chown -Rf root:root /mnt/ramdisk
ExecStart=/usr/bin/rsync -ar /mnt/persist_ramdisk/ /mnt/ramdisk
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target

endmsg1

	systemctl enable ramdisk-sync.service
	oldDir=/var/log 
	echo "Setup ramdisk for $oldDir"
	echo "$ramDir/$oldDir   $oldDir   none   bind   0 0" >>/etc/fstab
	mkdir -p $pRamDir$oldDir;mv $oldDir/* $pRamDir/$oldDir;rsync -ar $pRamDir/ $ramDir;mount --bind $ramDir/$oldDir $oldDir


fi
apt-get update -y
#apt source openssl

echo "Update root certificates"
update-ca-certificates

echo "Install common tools for further installation"
cd /tmp
wget -q https://raw.githubusercontent.com/SecuritasMachina/SecuritasMachina-Distrib/master/distrib/raspbian/package.lst

apt-get -q install -y $(awk -F: '/^[^#]/ { print $1 }' package.lst) 
if [ $? -eq 0 ]; then
    echo "Install of package.lst succeeded"
else
    echo "!! Install of package.lst failed !!"
    echo "Aborting install"
    exit
fi
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

apt -o Dpkg::Options::="--force-confnew" -q install ./*.deb -y --allow-downgrades
if [ $? -eq 0 ]; then
    echo "Install of squid with SSL succeeded"
else
    echo "!! Install of Squid failed !!"
    echo "Aborting install"
    exit
fi

echo 'disable further updates'
apt-mark hold squid squid-common
echo 'Shutdown & Disable Apache2'
update-rc.d apache2 disable
service stop apache2

echo "Sync RamDisk"
rsync -ar $ramDir/ $pRamDir

apt -o Dpkg::Options::="--force-confnew" -q install -y securitas-wall
if [ $? -eq 0 ]; then
    echo "Install of securitas-wall succeeded"
else
    echo "!! Install of securitas-wall failed !!"
    echo "Aborting install"
    exit
fi

apt -o Dpkg::Options::="--force-confnew" -q install -y securitas-wall-tomcat
if [ $? -eq 0 ]; then
    echo "Install of securitas-wall-tomcat succeeded"
else
    echo "!! Install of securitas-wall-tomcat failed !!"
    echo "Aborting install"
    exit
fi
apt -o Dpkg::Options::="--force-confnew" -q install -y securitas-wall-host
if [ $? -eq 0 ]; then
    echo "Install of securitas-wall-host succeeded"
else
    echo "!! Install of securitas-wall-host failed !!"
    echo "Aborting install"
    exit
fi
cp -r /etc/fstab /etc/fstab.bak --backup=numbered
oldDir=/var/lib/squidguard/db
echo "Setup ramdisk for $oldDir"
echo "$ramDir/$oldDir   $oldDir   none   bind   0 0" >>/etc/fstab
mkdir -p $pRamDir$oldDir;mv $oldDir/* $pRamDir/$oldDir;rsync -ar $pRamDir/ $ramDir;mount --bind $ramDir/$oldDir $oldDir
cp -r /etc/fstab /etc/fstab.bak --backup=numbered
oldDir=/var/lib/clamav
echo "Setup ramdisk for $oldDir"
echo "$ramDir/$oldDir   $oldDir   none   bind   0 0" >>/etc/fstab
mkdir -p $pRamDir$oldDir;mv $oldDir/* $pRamDir/$oldDir;rsync -ar $pRamDir/ $ramDir;mount --bind $ramDir/$oldDir $oldDir

echo "Sync RamDisk"
rsync -ar $ramDir/ $pRamDir
tune2fs -o journal_data_writeback,nobarrier /dev/mmcblk0p2
echo "Echo reduce swapping"
sysctl vm.swappiness=20

echo "Harden & Enable ssh"
if cat /etc/ssh/sshd_config | grep "Port 20022" ; then
     echo "Port 20022 already exists"
else
	echo "Adding Port 20022, MaxAuthTries 6, MaxSessions 2"
	echo "Port 20022" >> /etc/ssh/sshd_config
	echo "MaxAuthTries 3" >> /etc/ssh/sshd_config
	echo "MaxSessions 5" >> /etc/ssh/sshd_config
	#echo "TCPKeepAlive no" >> /etc/ssh/sshd_config
	echo "AllowAgentForwarding no" >> /etc/ssh/sshd_config
	echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config
	#echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config
	echo "Compression no" >> /etc/ssh/sshd_config
	echo "LogLevel verbose" >> /etc/ssh/sshd_config
	
	
fi
systemctl enable ssh
service ssh restart

echo "Increase performance furtheer by mounting all partitions on the SD card with the noatime,commit=1800 options"
read -rsp $'Press any key to restart or CTRL-c to abort...note may take 10 minutes to load virus and malware definitions' -n1 key
shutdown -r now
