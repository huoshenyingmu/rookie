#!/bin/bash
#auth:rookie
#date:2019-09-26
#作用:对es的索引进行快照，快照备份到s3上，并删除已经备份的快照的索引
server_IP=10.180.102.207
port=9200
user_name=elastic
user_passwd=h1nWsSY0fVvbRIx0h5Zo
index_name=suricata-http
datetime_dd=`date -d "-2 day" +%Y.%m.%d`
Num=0
# 磁盘报警阈值
disk_threshold=70

#读取index的时间，小于等于两天前(按当前时间算)的数据进行快照
Snapshotbackup() {
    for datedp in `curl -s --user ${user_name}:${user_passwd} https://${server_IP}:${port}/_cat/indices?v | awk '{print $3}' |grep "${index_name}"|awk -F "-" '{print $3}'`;do
        if [ ${datedp//./} -le ${datetime_dd//./} ];then
#           for index_back in `curl -s --user ${user_name}:${user_passwd} https://${server_IP}:${port}/_cat/indices?v | awk '{print $3}' |grep "${index_name}"`;do
#               curl --user ${user_name}:${user_passwd} -XPUT https://${server_IP}:${port}/_snapshot/backup/${index_back} -H 'Content-Type: application/json' -d '{ "indices": "'${index_back}'" }'
#           done
            index_back[${Num}]=${index_name}-${datedp}
        fi
        ((Num++))
    done
    curl -s --user ${user_name}:${user_passwd} -XPUT 'https://${server_IP}:${port}/_snapshot/backup/${index_name}-'`date +{%F-%T}`'' -H 'Content-Type: application/json' -d '{ "indices": '"`echo ${index_back[*]} | sed 's/\s\+/,/g'`"', "ignore_unavailable": true, "include_global_state": false}'
}

#删除已经完成的索引
Deleteindex() {
    for datedp in `curl -s --user ${user_name}:${user_passwd} https://${server_IP}:${port}/_cat/indices?v | awk '{print $3}' |grep "${index_name}"|awk -F "-" '{print $3}'`;do
        if [ ${datedp//./} -le ${datetime_dd//./} ];then
            index_back[${Num}]=${index_name}-${datedp}
        fi
        ((Num++))
    done
    curl -s --user ${user_name}:${user_passwd} -XDELETE https://${server_IP}:${port}/`echo ${index_back[*]} | sed 's/\s\+/,/g'`
}

#恢复快照索引
Restoreindex() {

}

#start
#check_root() {
#    disk_usage=`df -h | grep $(df -mP|egrep -v 'tmpfs|Used|:'|awk '{print $2,$6;}'|sort -nr|head -1|cut -d ' ' -f 2) | awk '{print $5}' | sed 's/%//'`
#    if [ ${disk_usage} -gt ${disk_threshold} ];then
#        echo "`date +%F-%H:%m:%S` 磁盘使用率标准为(${disk_threshold}%),已超标(disk_usage: ${disk_usage}% 开始备份计划! " >> /linngtian/logs/back_es_index.logs
#        Snapshotbackup
#        if [ $? -eq 0 ];then
#            Deleteindex
#        echo "备份的快照有：`echo ${index_back[*]} | sed 's/\s\+/,/g'`" >>  /linngtian/logs/back_es_index.logs
#    else
#        echo "`date +%F-%H:%m:%S` 磁盘使用率才为(${disk_usage}%),磁盘还可以支持下" >> /linngtian/logs/back_es_index.logs
#    fi
#}
Snapshotcompletion() {
    [[ `rpm -qa|grep jq|wc -l` = 0 ]] && yum -y install jq
    if [ `curl -s --user ${user_name}:${user_passwd} -XGET 'https://${server_IP}:${port}/_snapshot/backup/_all'?pretty | jq . | awk -F "["state"]" '/"state"/{print $0}'|grep -v SUCCESS |wc -l` = 0 ];then
        disk_usage=`df -h | grep $(df -mP|egrep -v 'tmpfs|Used|:'|awk '{print $2,$6;}'|sort -nr|head -1|cut -d ' ' -f 2) | awk '{print $5}' | sed 's/%//'`
        if [ ${disk_usage} -gt ${disk_threshold} ];then
            echo "`date +%F-%H:%m:%S` 磁盘使用率标准为(${disk_threshold}%),已超标(disk_usage: ${disk_usage}% 开始备份计划! " >> /linngtian/logs/back_es_index.logs
            Snapshotbackup
        fi
    else
        echo "`date +%F-%H:%m:%S` 磁盘使用率才为(${disk_usage}%),磁盘还可以支持下" >> /linngtian/logs/back_es_index.logs

}


main() {
    Snapshotcompletion
}