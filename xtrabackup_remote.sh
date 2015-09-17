#!/bin/bash - 
#===============================================================================
#
#          FILE: xtrabackup_remote.sh
# 
#         USAGE: ./xtrabackup_remote.sh 
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

# xtrabackup的相关配置
INNOBACKUPEX="innobackupex "
MY_CNF="/home/config/mysql/3307.backup.cnf"
MY_USER="xtrabackup"
MY_PASSWORD="xtrabackup"
MY_SOCKET="/home/socket/mysql/3307.sock"

# 远程备份机 文件名配置
REMOTE_HOST="dbbackup"
REMOTE_DIR="/home/backup/mysql/test"
LOCAL_LSN_FILE="~/.to_lsn_important"
DATE_NAME=`date +%Y-%m-%d-%H-%M-%S`
REMOTE_FILE=$DATE_NAME.tar.gz
LOCK_FILE="~/.mysql.backup.lock"
LOCAL_BACKUP_DIR="/home/backup/mysql/test/$DATE_NAME"

# 输出帮助信息
function usage()
{
    echo "Usage:"
    echo "-f db will be backuped fully with this parameter. If not , incrementally. "
}

#防止同时执行两个备份命令，发生冲突
if [ -f $LOCK_FILE ] ;then
    echo 'Mysql backup lockfile is locked!'
    exit 0
fi

full=0

while getopts "fh" arg #选项后面的冒号表示该选项需要参数
do
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

echo "backup dir is $REMOTE_DIR/$REMOTE_FILE"

# backup up db to remote host
echo "start to backup db!"`date +%Y-%m-%d-%H-%M-%S`
if [ "$full"x = "1"x ] ;then
    # 全量备份
    echo '1' > $LOCK_FILE
    $INNOBACKUPEX --defaults-file=$MY_CNF --user=$MY_USER --password=$MY_PASSWORD --socket=$MY_SOCKET ./ --stream=tar | gzip | ssh $REMOTE_HOST "cat - > $REMOTE_DIR/FULL-$REMOTE_FILE"
    ssh $REMOTE_HOST "cd $REMOTE_DIR;rm -f xtrabackup_checkpoints;tar zxfi $REMOTE_DIR/FULL-$REMOTE_FILE xtrabackup_checkpoints "
    toLSN=$( ssh $REMOTE_HOST "cat $REMOTE_DIR/xtrabackup_checkpoints|grep to_lsn|awk -F= '{gsub(/ /,\"\",\$2);print \$2}'" )
    if [ $toLSN ] ;then
        echo $toLSN > $LOCAL_LSN_FILE
    else
        echo 'no lsn from remote host!please check!'
    fi
else
    # 增量备份
    if [ -f $LOCAL_LSN_FILE ] ;then
        toLSN=`cat $LOCAL_LSN_FILE`
    fi

    if [ ! $toLSN ] ;then
        echo 'last LSN is not set !please check!'
        exit 0
    fi

    echo '1' > $LOCK_FILE
    mkdir -p $LOCAL_BACKUP_DIR
    echo "last to lsn is "$toLSN
    $INNOBACKUPEX --parallel=2 --defaults-file=$MY_CNF --user=$MY_USER --password=$MY_PASSWORD --socket=$MY_SOCKET --incremental --incremental-lsn=$toLSN $LOCAL_BACKUP_DIR 2>/tmp/innobackexLog
    toLSN=$( cd $LOCAL_BACKUP_DIR/*; cat xtrabackup_checkpoints|grep to_lsn|awk -F= '{gsub(/ /,"",$2);print $2}' )
    echo "new to lsn is "$toLSN;
    if [ $toLSN ] ;then
        echo $toLSN > $LOCAL_LSN_FILE
        cd $LOCAL_BACKUP_DIR/*;tar zc .|ssh $REMOTE_HOST "cat - > $REMOTE_DIR/$REMOTE_FILE"
        echo "save file to $REMOTE_HOST @ $REMOTE_DIR/$REMOTE_FILE"
    else
        echo 'no lsn from local backup file!delete remote backup file!'$LOCAL_BACKUP_DIR/$REMOTE_FILE
    fi
    echo "remove $LOCAL_BACKUP_DIR"
    rm -rf $LOCAL_BACKUP_DIR
fi

rm -f $LOCK_FILE
echo "end to backup db!"`date +%Y-%m-%d-%H-%M-%S`

