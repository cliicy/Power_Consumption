#!/usr/bin/bash

timestamp=`date +%Y%m%d_%H%M%S`
disk=sfdv0n1

#init clean card 
#sudo sfx-nvme sfx set-feature -f 0xac /dev/${disk} -v 3840 --force
#sudo sfx-nvme format /dev/sfdv0n1 -l 1 --force
#sudo sfx-nvme sfx set-feature -f 0xdc /dev/sfxv0 --force

comp_ratio=0
comp_opt_str=""; 

if [ "${comp_ratio}" != "" ]; 
then
    comp_opt_str=" --buffer_compress_chunk=4k --buffer_compress_percentage=${comp_ratio} "    
fi

if [ ! -d "${timestamp}" ]; then mkdir ${timestamp}; fi
if [ ! -d "${timestamp}/pre" ]; then mkdir ${timestamp}/pre; fi
if [ ! -d "${timestamp}/seqw" ]; then mkdir ${timestamp}/seqw; fi
if [ ! -d "${timestamp}/randw" ]; then mkdir ${timestamp}/randw; fi
if [ ! -d "${timestamp}/randmix_rw" ]; then mkdir ${timestamp}/randmix_rw; fi

#precondition:128K seq write 1 loops
iostat -dxmct 1 ${disk} > ${timestamp}/pre/${disk}.iostat &
sh powerstatus.sh ${timestamp}/pre ${disk} &
sudo fio --ioengine=libaio --direct=1 --thread --norandommap --filename=/dev/${disk} --name=init_seq --output=${timestamp}/pre/init_seq.log --rw=write --bs=128k --numjobs=1 --iodepth=128 ${comp_opt_str} --loops=1 

##大压力顺序写IO，运行脚本如下：
iostat -dxmct 1 ${disk} > ${timestamp}/seqw/${disk}.iostat &
sh powerstatus.sh ${timestamp}/seqw ${disk} &
sudo fio --name=seq_write --filename=/dev/${disk} --ioengine=libaio --direct=1 --thread=1 --numjobs=1 --iodepth=128 --rw=write --bs=128k --runtime=1h --time_based=1 --size=100% --group_reporting --write_bw_log=${timestamp}/seqw/128K_seqW_bw.log ${comp_opt_str} --output=${timestamp}/seqw/fio-128K_seqW.out

##大压力随机写IO，运行脚本如下：
iostat -dxmct 1 ${disk} > ${timestamp}/randw/${disk}.iostat &
sh powerstatus.sh ${timestamp}/randw ${disk} &
sudo fio --name=random_write --filename=/dev/${disk} --ioengine=libaio --direct=1 --thread=1 --numjobs=1 --iodepth=128 --rw=randwrite --bs=4k --runtime=1h --time_based=1 --size=100% --norandommap=1 --randrepeat=0 --group_reporting --write_bw_log=${timestamp}/randw/128K_randW_bw.log ${comp_opt_str} --output=${timestamp}/randw/fio-128K_randW.out

##大压力混合随机写IO，运行脚本如下：
iostat -dxmct 1 ${disk} > ${timestamp}/randmix_rw/${disk}.iostat &
sh powerstatus.sh ${timestamp}/randmix_rw ${disk} &
sudo fio --name=random_mix --filename=/dev/${disk} --ioengine=libaio --direct=1 --thread=1 --numjobs=8 --iodepth=128 --rw=randrw --rwmixread=50 --bs=4k --runtime=1h --time_based=1 --size=100% --norandommap=1 --randrepeat=0 --group_reporting --write_bw_log=${timestamp}/randmix_rw/128K_mixrw_bw.log ${comp_opt_str} --output=${timestamp}/randmix_rw/fio-128K_mixrw.out
