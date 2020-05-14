#!/bin/bash
#auth:rookie
#date:2019-09-26
#作用:对es的索引进行快照，快照备份到s3上，并删除已经备份的快照的索引
server_IP=10.180.102.207
port=9200
user_name=elastic
user_passwd=h1nWsSY0fVvbRIx0h5Zo
index_name=wazuh-alerts
#当前时间的时间戳
datetime=`date +%s`
#读取index的时间，小于等于两天前(按当前时间算)的数据进行快照
Snapshotbackup() {
    for datedp in `curl -s --user ${user_name}:${user_passwd} https://${server_IP}:${port}/_cat/indices?v | awk '{print $3}' |grep "${index_name}"`;do
        dateindex=`echo ${datedp}|awk -F "-" '{print $4}'|tr '.' '-'`
        dateok=`date -d ${dateindex} +%s`
        #输出所有时间大于等于两天的内容
        if [ $((datetime - dateok)) -ge 172800 ];then
        #把正确的值输出到数组中
            index_back[${Num}]=${datedp}
        fi
        ((Num++))
    done
    #把数组输出到index文件中，并以逗号隔开
    echo ${index_back[*]} | sed 's/[ ][ ]*/,/g'  > /tmp/index.txt
    #开始进行存储，并将/tmp/index.txt的文件进行格式化
    curl -k -s --user ${user_name}:${user_passwd} -XPUT 'https://'${server_IP}':'${port}'/_snapshot/backup/'${index_name}'-'`date +{%F-%T}`'' -H 'Content-Type: application/json' -d '{ "indices": "'`echo ${index_back[*]} | sed 's/[ ][ ]*/,/g'`'", "ignore_unavailable": true, "include_global_state": false}'
	echo -e "\n"
}

Deleteindex() {
    if [ -s /tmp/index.txt ];then
        #curl -s --user ${user_name}:${user_passwd} -XDELETE https://${server_IP}:${port}/`cat /tmp/index.txt | while read line; do echo $line; done`
	rm -rf /tmp/index.txt
    fi
}


main() {
    Deleteindex
    Snapshotbackup
}

main
