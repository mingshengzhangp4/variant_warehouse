
## opaque save arrays ##
DATE="2015_06_01"
saved_path='/home/scidb/tcga_save'
iquery -aq "filter(project(list(), name), regex(name, '(.*)$DATE(.*)'))"|awk '{print $2}'|xargs -I {} iquery -anq "save({}, '$saved_path/{}', 0, 'opaque')"

## zip ##

ls |grep ${DATE}|xargs -I {} tar -czf TCGA_${DATE}_tar.gz {}

## tar.gz file transfer ##

scp scidb@p4-node001:~/ ./TCGA_${DATE}_tar.gz

## load back into scidb ##

   # initialized the arrays with correct shema #
   bash /home/scidb/variant_warehouse/load_tcga/tcga_dev/scidbArray_save_load.sh

   # unzip and load the arrays #
   tar -xzf TCGA_${DATE}_tar.gz

   ls|grep ${DATE}|xargs -I {} iquery -anq "load({}, 0, 'opaque')"
 



