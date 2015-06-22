#!/bin/bash

if [ $# -ne 1 ]; then
 echo "Please provide a single input file"
 exit 1
fi

FILE=$1
filedir=`dirname $FILE`
pushd $filedir >> /dev/null
FILE="`pwd`/`basename $FILE`"
if [ ! -f $FILE ] ; then
 echo "Cannot find file $FILE!"
 exit 1
fi
popd > /dev/null
mydir=`dirname $0`
pushd $mydir >> /dev/null
mydir=`pwd`
fifo_path=$mydir/load.fifo

function log()
{
  echo "`date $DATESTRING` > $1"
}

function delete_old_versions()
{
   ARRAY_NAME=$1
   MAX_VERSION=`iquery -ocsv -aq "aggregate(versions($ARRAY_NAME), max(version_id) as max_version)" | tail -n 1`
   if [ $MAX_VERSION != "null" -a $MAX_VERSION -gt 0 ] ; then
     iquery -anq "remove_versions($ARRAY_NAME, $MAX_VERSION)" > /dev/null
   fi
}

function cleanup()
{
  set +e
  rm -rf $fifo_path
}

function error()
{
  echo "`date $DATESTRING` !!! ERROR !!! $1" >&2
  echo "Cleaning up and exiting"
  cleanup
  exit 1
}

cleanup

NUM_CHROMOSOMES=`(iquery -otsv -aq "op_count(DBNSFP_V3_CHROMOSOME)" > /dev/null 2>&1 && echo 1) || echo 0`
if [ $NUM_CHROMOSOMES -ne 1 ] ; then
  error "Did not find the expected chromosome array. Did you run recreate_dbnsfp.sh first?"
fi

log "Loading $FILE"
#Find the right thing to cat the file with
prog="cat"
if [ `file $FILE | grep bzip | wc -l` -ge 1 ]; then
 prog="bzcat"
elif [ `file $FILE | grep gzip | wc -l` -ge 1 ]; then
 prog="zcat"
fi
log "Piping file through $prog"
#Entering the clean zone:

set -e
mkfifo $fifo_path
$prog $FILE > $fifo_path &

log "Starting load"

time iquery -naq "
insert(
 redimension(
  apply(
   index_lookup(
    parse(
     split(
      '$fifo_path',
      'lines_per_chunk=10000',
      'header=1'
     ),
     'num_attributes=112',
     'chunk_size=10000'
    ),
    DBNSFP_V3_CHROMOSOME,
    a0, chromosome_id
   ),
   pos                               , dcast(a1   ,int64(null)),
   ref                               , a2   ,
   alt                               , a3   ,
   aaref                             , a4   ,
   aaalt                             , a5   ,
   rs_dbSNP142                       , a6   ,
   hg19_chr                          , a7   ,
   hg19_pos                          , dcast(a8   ,int64(null)) ,
   hg18_chr                          , a9   ,
   hg18_pos                          , dcast(a10  ,int64(null)) ,
   genename                          , a11   ,
   cds_strand                        , a12   ,
   refcodon                          , a13   ,
   codonpos                          , dcast(a14  ,uint8(null)) ,
   codon_degeneracy                  , a15   ,
   Ancestral_allele                  , a16   ,
   AltaiNeandertal                   , a17   ,
   Denisova                          , a18   ,
   Ensembl_geneid                    , a19   ,
   Ensembl_transcriptid              , a20   ,
   Ensembl_proteinid                 , a21   ,
   aapos                             , a22   ,
   SIFT_score                        , a23   ,
   SIFT_converted_rankscore          , dcast(a24  ,double(null)) ,
   SIFT_pred                         , a25   ,
   Uniprot_acc_Polyphen2             , a26   ,
   Uniprot_id_Polyphen2              , a27   ,
   Uniprot_aapos_Polyphen2           , a28   ,
   Polyphen2_HDIV_score              , a29   ,
   Polyphen2_HDIV_rankscore          , dcast(a30  ,double(null)) ,
   Polyphen2_HDIV_pred               , a31   ,
   Polyphen2_HVAR_score              , a32   ,
   Polyphen2_HVAR_rankscore          , dcast(a33  ,double(null)) ,
   Polyphen2_HVAR_pred               , a34   ,
   LRT_score                         , dcast(a35  ,double(null)) ,
   LRT_converted_rankscore           , dcast(a36  ,double(null)) ,
   LRT_pred                          , a37   ,
   LRT_Omega                         , dcast(a38  ,double(null)) ,
   MutationTaster_score              , a39   ,
   MutationTaster_converted_rankscore, dcast(a40  ,double(null)) ,
   MutationTaster_pred               , a41   ,
   MutationTaster_model              , a42   ,
   MutationTaster_AAE                , a43   ,
   Uniprot_id_MutationAssessor       , a44   ,
   Uniprot_variant_MutationAssessor  , a45   ,
   MutationAssessor_score            , dcast(a46  ,double(null)) ,
   MutationAssessor_rankscore        , dcast(a47  ,double(null)) ,
   MutationAssessor_pred             , a48   ,
   FATHMM_score                      , dcast(a49  ,double(null)) ,
   FATHMM_converted_rankscore        , dcast(a50  ,double(null)) ,
   FATHMM_pred                       , a51   ,
   PROVEAN_score                     , a52   ,
   PROVEAN_converted_rankscore       , dcast(a53  ,double(null)) ,
   PROVEAN_pred                      , a54   ,
   MetaSVM_score                     , dcast(a55  ,double(null)) ,
   MetaSVM_rankscore                 , dcast(a56  ,double(null)) ,
   MetaSVM_pred                      , a57   ,
   MetaLR_score                      , dcast(a58  ,double(null)) ,
   MetaLR_rankscore                  , dcast(a59  ,double(null)) ,
   MetaLR_pred                       , a60   ,
   Reliability_index                 , dcast(a61  ,uint8(null)) ,
   GERPPP_NR                         , dcast(a62  ,double(null)) ,
   GERPPP_RS                         , dcast(a63  ,double(null)) ,
   GERPPP_RS_rankscore               , dcast(a64  ,double(null)) ,
   phyloP7way_vertebrate             , dcast(a65  ,double(null)) ,
   phyloP7way_vertebrate_rankscore   , dcast(a66  ,double(null)) ,
   phastCons7way_vertebrate          , dcast(a67  ,double(null)) ,
   phastCons7way_vertebrate_rankscore, dcast(a68  ,double(null)) ,
   SiPhy_29way_pi                    , a69   ,
   SiPhy_29way_logOdds               , dcast(a70  ,double(null)) ,
   SiPhy_29way_logOdds_rankscore     , dcast(a71  ,double(null)) ,
   KGp3_AC                           , dcast(a72  ,int64(null)) ,
   KGp3_AF                           , dcast(a73  ,double(null)) ,
   KGp3_AFR_AC                       , dcast(a74  ,int64(null)) ,
   KGp3_AFR_AF                       , dcast(a75  ,double(null)) ,
   KGp3_EUR_AC                       , dcast(a76  ,int64(null)) ,
   KGp3_EUR_AF                       , dcast(a77  ,double(null)) ,
   KGp3_AMR_AC                       , dcast(a78  ,int64(null)) ,
   KGp3_AMR_AF                       , dcast(a79  ,double(null)) ,
   KGp3_EAS_AC                       , dcast(a80  ,int64(null)) ,
   KGp3_EAS_AF                       , dcast(a81  ,double(null)) ,
   KGp3_SAS_AC                       , dcast(a82  ,int64(null)) ,
   KGp3_SAS_AF                       , dcast(a83  ,double(null)) ,
   TWINSUK_AC                        , dcast(a84  ,int64(null)) ,
   TWINSUK_AF                        , dcast(a85  ,double(null)) ,
   ALSPAC_AC                         , dcast(a86  ,int64(null)) ,
   ALSPAC_AF                         , dcast(a87  ,double(null)) ,
   ESP6500_AA_AC                     , dcast(a88  ,int64(null)) ,
   ESP6500_AA_AF                     , dcast(a89  ,double(null)) ,
   ESP6500_EA_AC                     , dcast(a90  ,int64(null)) ,
   ESP6500_EA_AF                     , dcast(a91  ,double(null)) ,
   ExAC_AC                           , dcast(a92  ,int64(null)) ,
   ExAC_AF                           , dcast(a93  ,double(null)) ,
   ExAC_Adj_AC                       , dcast(a94  ,int64(null)) ,
   ExAC_Adj_AF                       , dcast(a95  ,double(null)) ,
   ExAC_AFR_AC                       , dcast(a96  ,int64(null)) ,
   ExAC_AFR_AF                       , dcast(a97  ,double(null)) ,
   ExAC_AMR_AC                       , dcast(a98  ,int64(null)) ,
   ExAC_AMR_AF                       , dcast(a99  ,double(null)) ,
   ExAC_EAS_AC                       , dcast(a100  ,int64(null)) ,
   ExAC_EAS_AF                       , dcast(a101  ,double(null)) ,
   ExAC_FIN_AC                       , dcast(a102  ,int64(null)) ,
   ExAC_FIN_AF                       , dcast(a103  ,double(null)) ,
   ExAC_NFE_AC                       , dcast(a104  ,int64(null)) ,
   ExAC_NFE_AF                       , dcast(a105  ,double(null)) ,
   null_SAS_AC                       , dcast(a106  ,int64(null)) ,
   ExAC_SAS_AF                       , dcast(a107  ,double(null)) ,
   clinvar_rs                        , a108   ,
   clinvar_clnsig                    , dcast(a109, int8(null)),
   clinvar_trait                     , a110   ,
   Interpro_domain                   , trim(a111, int_to_char(13))   -- silly DOS style carriage returns. Come on now!
  ),
  DBNSFP_V3_VARIANT
 ),  
 DBNSFP_V3_VARIANT
)"

delete_old_versions DBNSFP_V3_VARIANT
cleanup

log "Done"

