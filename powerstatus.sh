output_dir=$1
disk=/dev/$2
pc_log=${output_dir}/pc.status


for i in {1..2000};
do
    timestamp=`date +%Y%m%d_%H:%M:%S`
    echo "power consumption at: " `date +%Y-%m-%d\ %H:%M:%S` >> ${pc_log}
    sudo sfx-status ${disk}  | grep "Power Consumption:" | awk '{print $3,$4}' >> ${pc_log}
    sleep 5
done

