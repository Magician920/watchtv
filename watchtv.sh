#!/bin/sh
#在根目录创建allinone文件夹
mkdir /allinone
#授权755
chmod 755 /allinone
#下载allinone-update.sh文件到/allinone
wget -P /allinone https://github.com/Magician920/watchtv/blob/main/allinone-update.sh
#下载allinone文件到/etc/init.d
wget -P /etc/init.d/ https://github.com/Magician920/watchtv/blob/main/allinone
#授权allinone-update.sh可执行
chmod +x /allinone/allinone-update.sh
#授权allinone可执行
chmod +x /etc/init.d/allinone
#配置allinone开机自启
/etc/init.d/allinone enable
#启动allinone
/etc/init.d/allinone start
#执行allinone-update.sh
sh /allinone/allinone-update.sh
#创建计划任务
crontab -l > cron.cron
echo '0 10 * * * /allinone/allinone-update.sh' >> cron.cron
echo '0 1 * * * echo "" > /tmp/log/allinone.log' >> cron.cron
crontab cron.cron