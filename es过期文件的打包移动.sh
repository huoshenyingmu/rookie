#!/bin/bash
data=/lingtian/data/elasticsearch
S3_data=/lingtian/S3-data
#取得每个分区的使用百分比（不要百分号）
percent=`df -k | grep -v Filesystem| awk '{print int($5)}'`
 
#循环判断分区使用率是否超过90%
for each_one in $percent
do
    #判断使用率是否超过90%
    if [ $each_one -ge 90 ];then
        #如果超过90 则清理文件，根据文件方式进行压缩包的移动
        [[ `mountpoint -q ${S3_data};echo $?` = 0 ]] && cd ${S3_data}/data/Compressed_channel;tar -zcvf elasticsearch_`date +"%F-%T"`.tar.gz ``
    fi
done