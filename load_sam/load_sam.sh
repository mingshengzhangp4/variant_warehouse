
#  samtools view /home/scidb/mzhang/cp_file/GS000038929-ASM.normal.sort.bam|head -20000000 > /home/scidb/mzhang/paradigm4_lab/variant_warehouse/load_sam/cg.sam
#  iquery -anq "remove(sam_tmp)" >/dev/null 2>&1
#  iquery -anq "remove(sam_array)" >/dev/null 2>&1
#  iquery -anq "store(aio_input('/home/scidb/mzhang/paradigm4_lab/variant_warehouse/load_sam/cg.sam', 'num_attributes=12'), sam_tmp)"


#  # read and write from nfs mounted dir
#  sudo sh -c 'samtools view /home/scidb/mzhang/cp_file/GS000038929-ASM.normal.sort.bam>/home/scidb/mzhang/cp_file/cg.sam'
#  iquery -anq "remove(sam_tmp)" >/dev/null 2>&1
#  iquery -anq "remove(sam_array)" >/dev/null 2>&1
#  iquery -anq "store(aio_input('/home/scidb/mzhang/cp_file/cg.sam', 'num_attributes=12'), sam_tmp)"

#  iquery -anq "remove(sam_array)" >/dev/null 2>&1
#  
#  iquery -aq "create array sam_array <qname:string,flag:int64 null,rname:string null,pos:int64 null,mapq:int64 null,cigr:string null,rnext:string null,pnext:int64 null,tlen:int64 null,seq:string null compression 'zlib',qual:string null compression 'zlib',rg:string null> [q_no=0:*,100000,0]"
#  
#  
#  
#  
#  iquery -anq "
#  insert(
#    redimension(
#      substitute(
#        project(
#          apply(
#            -- unpack to get unique q_no
#            unpack(
#              sam_tmp,
#              q_no),
#            
#            qname, a0,
#            flag, dcast(a1, int64(missing(1))),
#            rname, a2,
#            pos, dcast(a3, int64(missing(1))),
#            mapq, dcast(a4, int64(missing(1))),
#            cigr, a5,
#            rnext, a6,
#            pnext, dcast(a7, int64(missing(1))),
#            tlen, dcast(a8, int64(missing(1))),
#            seq, a9,
#            qual, a10,
#            rg, a11
#            ),
#          qname,
#          flag,
#          rname,
#          pos,
#          mapq,
#          cigr,
#          rnext,
#          pnext,
#          tlen,
#          seq,
#          qual,
#          rg
#          ),
#        build(<subval:string>[i=0:1,1,0], '_'),
#        qname
#        ),
#      sam_array
#      ),
#    sam_array)"
 
# iquery -anq "store(between(sam_array, 0, 10000000), work_array)"

iquery -anq "remove(sam_pileup)"

iquery -aq "create array sam_pileup
<
qname: string,
flag: int64 null,
rname: string null,
mapq: int64 null,
cigr: string null,
rnext: string null,
pnext: int64 null,
tlen: int64 null,
rg: string null,
base: char null,
base_qual: char null>
[q_no=0:*, 1000000,0,
coord =0:*, 10000000,0
]"

#[q_no=0:*, 10000000,0,
# base_index_in_read=0:27, 28, 0,
# coord =0:*, 1000000,0]"

#  iquery -anq "
#    consume(
#      project(
#        apply(
#          apply(
#            cross_join(
#              sam_array,
#              build(<pos_in_read:int64>[base_index_in_read=0:27,28,0], base_index_in_read)
#              ),
#            sgnd_pos_in_read, iif(tlen>0, pos_in_read, -pos_in_read),
#            base,
#            iif(pos_in_read > strlen(seq)-1, null, substr(seq, pos_in_read, 1)),
#            base_qual,
#            iif(pos_in_read > strlen(seq)-1, null, substr(qual, pos_in_read, 1))
#            ),
#          coord,
#          pos + sgnd_pos_in_read),
#        qname,
#        flag,
#        rname,
#        mapq,
#        cigr,
#        rnext,
#        pnext,
#        tlen,
#        rg,
#        coord,
#        base,
#        base_qual
#        )
#    )"







iquery -anq "
insert(
  redimension(
    project(
      apply(
        apply(
          cross_join(
            sam_array,
            build(<pos_in_read:int64>[base_index_in_read=0:27,28,0], base_index_in_read)
            ),
          sgnd_pos_in_read, iif(tlen>0, pos_in_read, -pos_in_read),
          base,
          iif(pos_in_read > strlen(seq)-1, null, char(substr(seq, pos_in_read, 1))),
          base_qual,
          iif(pos_in_read > strlen(seq)-1, null, char(substr(qual, pos_in_read, 1)))
          ),
        coord,
        pos + sgnd_pos_in_read),
      qname,
      flag,
      rname,
      mapq,
      cigr,
      rnext,
      pnext,
      tlen,
      rg,
      coord,
      base,
      base_qual
      ),
    sam_pileup
    ),
  sam_pileup

  )"


