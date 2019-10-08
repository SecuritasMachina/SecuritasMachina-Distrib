if cat /etc/fstab | grep "ramdisk" ; then
     echo "RAM disk already exists"
else
	echo "Adding RAM disk"
	cp -r /etc/fstab /etc/fstab --backup=numbered
	#create fstab entries
	echo "tmpfs  /mnt/ramdisk  tmpfs  rw,size=512M  0   0" >>/etc/fstab
	mount -t tmpfs -o size=512m myramdisk /mnt/ramdisk
#setup sync service
cat > /lib/systemd/system/ramdisk-sync.service <<'endmsg1'
[Unit]
Before=umount.target

[Service]
Type=oneshot
User=root
ExecStartPre=/bin/chown -Rf root:syslog /mnt/ramdisk
ExecStart=/usr/bin/rsync -ar /mnt/persist_ramdisk/ /mnt/ramdisk
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target

endmsg1

	systemctl enable ramdisk-sync.service
	oldDir=/var/lib/squidguard/db
	pRamDir=/mnt/persist_ramdisk
	ramDir=/mnt/ramdisk
	echo "Setup ramdisk for $oldDir"
	mkdir -p $pRamDir$oldDir;mv $oldDir/* $pRamDir/$oldDir;rsync -ar /mnt/persist_ramdisk/ /mnt/ramdisk;mount --bind $ramDir/$oldDir $oldDir
	oldDir=/var/log 
	echo "Setup ramdisk for $oldDir"

        mkdir -p $pRamDir$oldDir;mv $oldDir/* $pRamDir/$oldDir;rsync -ar /mnt/persist_ramdisk/ /mnt/ramdisk;mount --bind $ramDir/$oldDir $oldDir

fi

