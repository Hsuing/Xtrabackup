#!/bin/bash - 
#===============================================================================
#
#          FILE: xtrabackup.sh
# 
#         USAGE: ./xtrabackup.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Xiong.Han 
#            E-MAIL: hxopensource.163.com 
#  ORGANIZATION: 
#       CREATED: 2015年07月22日 09:32
#      REVISION:  ---
#===============================================================================

export PATH=$PATH:/xtrabackup

#全量和增量备份目录
BAKDIR_FULL=/data/full
INCRE=incre
DATA=/data
BAKDIR_INRE=$DATA/$INCRE
BAKDIR_INRE2=$DATA/incre2

#xtrabackup的相关配置
CONF=/etc/my.cnf
PASSWD=123456
NAME=back
SOCKET=/var/lib/mysql/mysql.sock

LOCK_FILE=~/.mysql_backup.lock
# 输出帮助信息
function usage(){
	echo "Usage:"
	echo "-f db will be backuped fully with this parameter."
}

#防止同时执行两个备份命令，发生冲突
if [ -f $LOCK_FILE ] ;then
    echo 'Mysql backup lockfile is locked!'
    exit 0
fi

full=0

while getopts "fh" arg #选项后面的冒号表示该选项需要参数
d
    case $arg in
        f)
            full=1
            ;;
        h)  # 输出帮助信息
            usage
            exit 0
            ;;
    esac
done

file=`ls $BAKDIR_FULL 2> /dev/null`

#创建目录
if [ ! -d "$BAKDIR_FULL" ] && [ ! -d "$BAKDIR_INRE" ];then
	mkdir -p $BAKDIR_FULL
	mkdir -p $BAKDIR_INRE
fi

if [ -z "$file" ]
then
	echo '1' > $LOCK_FILE

	#第一次全量备份(以后不再全备)
	innobackupex --user=$NAME --password=$PASSWD  --socket=$SOCKET  $BAKDIR_FULL
	FULLNAME=$(dir "$BAKDIR_FULL")
	innobackupex --user=$NAME --password=$PASSWD  --socket=$SOCKET --incremental-basedir=$BAKDIR_FULL/$FULLNAME --incremental  $BAKDIR_INRE 
else
	#以增量的增量备份
	#ADDNAME=$(ls -tl $BAKDIR_INRE | sed -n 2p | awk '{print $9}')
        
	#以第一份为基点进行增量备份
	echo '1' > $LOCK_FILE
	ADDNAME=$(ls -tl $BAKDIR_INRE | sed -n '$p' | awk '{print $9}')
	innobackupex  --user=$NAME --password=$PASSWD --incremental-basedir=$BAKDIR_INRE/$ADDNAME --incremental $BAKDIR_INRE2
fi
	rm -rf $LOCK_FILE
