
## opaque save arrays ##
DATE=2015_06_01
saved_path=/home/scidb/tcga_save
mkdir -p $saved_path
iquery -aq "filter(project(list(), name), regex(name, '(.*)$DATE(.*)'))"|awk 'NR>1 {print $2}'|xargs -I {} iquery -anq "save({}, '$saved_path/{}', 0, 'opaque')"

select yn in "yes" "no"; do
    case "$yn" in
        yes) break;;
         no) exit 1;;
    esac
done

## zip ##

cd $saved_path
# ls |grep ${DATE}|xargs -I {} tar -cvf - {}|pigz TCGA_opaque.tar.gz

# ## tar.gz file transfer ##

#[scidb@P4-NODE001 ~]$ scp scidb@54.174.6.43:~/tcga_save/TCGA_opaque.tar.gz ~/
# Warning: Permanently added '54.174.6.43' (RSA) to the list of known hosts.
# scidb@54.174.6.43's password:
#


## direct transfer of unzipped file ##
[scidb@P4-NODE001 ~]$ nohup scp scidb@54.174.6.43:~/tcga_save/* ~/




## load back into scidb ##

   # initialized the arrays with correct shema #

[scidb@P4-NODE001 ~]$
   bash /home/scidb/variant_warehouse/load_tcga/array_init2load_saved_array.sh

#    # unzip and load the arrays #
#    pigz -d TCGA_opaque_tar.gz 
#    OR
#    tar -xzf TCGA_opaque_tar.gz

# debug mode #
 [scidb@P4-NODE001 ~]$
  ls /home/scidb/mzhang/variant_warehouse/load_tcga/TCGA_opaque_save|grep ${DATE}|xargs -tp -I {} iquery -aq "load({}, '/home/scidb/mzhang/variant_warehouse/load_tcga/TCGA_opaque_save/{}', 0, 'opaque')"
 
# batch mode #

 [scidb@P4-NODE001 ~]$
  ls /home/scidb/mzhang/variant_warehouse/load_tcga/TCGA_opaque_save|grep ${DATE}|xargs -I {} iquery -anq "load({}, '/home/scidb/mzhang/variant_warehouse/load_tcga/TCGA_opaque_save/{}', 0, 'opaque')"
 
