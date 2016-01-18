
#  samtools view /mnt/temp/GS000038929-ASM.normal.sort.bam
#    |head -100000000 > ~/Paradigm4_labs/my_variant_warehouse/load_sam/cg.sam
# sudo touch /home/scidb/mzhang/cp_file/cg.sam
sudo sh -c 'samtools view /home/scidb/mzhang/cp_file/GS000038929-ASM.normal.sort.bam>/home/scidb/mzhang/cp_file/cg.sam'


iquery -anq "remove(sam_tmp)" >/dev/null 2>&1
iquery -anq "remove(sam_array)" >/dev/null 2>&1


iquery -anq "store(aio_input('/home/scidb/mzhang/paradigm4_lab/variant_warehouse/load_sam/cg.sam', 'num_attributes=12'), sam_tmp)"


iquery -anq "create array sam_array <qname:string,flag:int64 null,rname:string null,pos:int64 null,mapq:int64 null,cigr:string null,rnext:string null,pnext:int64 null,tlen:int64 null,seq:string null compression 'zlib',qual:string null compression 'zlib',rg:string null> [line_no=0:9999999,10000000,0]"




iquery -anq "
insert(
  redimension(
    substitute(
      project(
        apply(
          unpack(
            sam_tmp,
            q_no),
          
          qname, a0,
          flag, dcast(a1, int64(missing(1))),
          rname, a2,
          pos, dcast(a3, int64(missing(1))),
          mapq, dcast(a4, int64(missing(1))),
          cigr, a5,
          rnext, a6,
          pnext, dcast(a7, int64(missing(1))),
          tlen, dcast(a8, int64(missing(1))),
          seq, a9,
          qual, a10,
          rg, a11
          ),
        qname,
        flag,
        rname,
        pos,
        mapq,
        cigr,
        rnext,
        pnext,
        tlen,
        seq,
        qual,
        rg
        ),
      build(<subval:string>[i=0:1,1,0], '_'),
      qname
      ),
    sam_array
    ),
  sam_array)"


