Xtrabackup简介
Percona XtraBackup是开源免费的MySQL数据库热备份软件，它能对InnoDB和XtraDB存储引擎的数据库非阻塞地备份（对于MyISAM的备份同样需要加表锁）。XtraBackup支持所有的Percona Server、MySQL、MariaDB和Drizzle。
XtraBackup优势 ：
1、无需停止数据库进行InnoDB热备
2、增量备份MySQL
3、流压缩到传输到其它服务器
4、能比较容易地创建主从同步
5、备份MySQL时不会增大服务器负载

注意:
    Xtrabackup2.0.x  只适用mysql5.5以下,mysql5.5以上需要Xtrabackup2.1.x 或者 Xtrabackup2.2.x
	
