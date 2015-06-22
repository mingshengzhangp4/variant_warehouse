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

NUM_CHROMOSOMES=`(iquery -otsv -aq "op_count(DBNSFP_V2p9_CHROMOSOME)" > /dev/null 2>&1 && echo 1) || echo 0`
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
     'num_attributes=119',
     'chunk_size=10000'
    ),
    DBNSFP_V2p9_CHROMOSOME,
    a0, chromosome_id
   ),
  pos                               , dcast(a1   ,      int64(null)),
  ref                               , iif(  a2   = '.', string(null), a2),
  alt                               , iif(  a3   = '.', string(null), a3),
  aaref                             , iif(  a4   = '.', string(null), a4),
  aaalt                             , iif(  a5   = '.', string(null), a5),
  rs_dbSNP141                       , iif(  a6   = '.', string(null), a6),
  hg18_pos                          , dcast(a7   ,      int64(null)),
  hg38_chr                          , iif(  a8   = '.', string(null), a8),
  hg38_pos                          , dcast(a9   ,      int64(null)),
  genename                          , iif(  a10  = '.', string(null), a10),
  Uniprot_acc                       , iif(  a11  = '.', string(null), a11),
  Uniprot_id                        , iif(  a12  = '.', string(null), a12),
  Uniprot_aapos                     , iif(  a13  = '.', string(null), a13),
  Interpro_domain                   , iif(  a14  = '.', string(null), a14),
  cds_strand                        , iif(  a15  = '.', string(null), a15),
  refcodon                          , iif(  a16  = '.', string(null), a16),
  SLR_test_statistic                , dcast(a17  ,      double(null)),
  codonpos                          , dcast(a18  ,      uint8(null)),
  fold_degenerate                   , dcast(a19  ,      uint8(null)),
  Ancestral_allele                  , iif(  a20  = '.', string(null), a20),
  Ensembl_geneid                    , iif(  a21  = '.', string(null), a21),
  Ensembl_transcriptid              , iif(  a22  = '.', string(null), a22),
  aapos                             , iif(  a23  = '.', string(null), a23),
  aapos_SIFT                        , iif(  a24  = '.', string(null), a24),
  aapos_FATHMM                      , iif(  a25  = '.', string(null), a25),
  SIFT_score                        , iif(  a26  = '.', string(null), a26),
  SIFT_converted_rankscore          , dcast(a27  ,      double(null)),
  SIFT_pred                         , iif(  a28  = '.', string(null), a28),
  Polyphen2_HDIV_score              , iif(  a29  = '.', string(null), a29),
  Polyphen2_HDIV_rankscore          , dcast(a30  ,      double(null)),
  Polyphen2_HDIV_pred               , iif(  a31  = '.', string(null), a31),
  Polyphen2_HVAR_score              , iif(  a32  = '.', string(null), a32),
  Polyphen2_HVAR_rankscore          , dcast(a33  ,      double(null)),
  Polyphen2_HVAR_pred               , iif(  a34  = '.', string(null), a34),
  LRT_score                         , dcast(a35  ,      double(null)),
  LRT_converted_rankscore           , dcast(a36  ,      double(null)),
  LRT_pred                          , iif(  a37  = '.', string(null), a37),
  MutationTaster_score              , iif(  a38  = '.', string(null), a38),
  MutationTaster_converted_rankscore, dcast(a39  ,      double(null)),
  MutationTaster_pred               , iif(  a40  = '.', string(null), a40),
  MutationAssessor_score            , dcast(a41  ,      double(null)),
  MutationAssessor_rankscore        , dcast(a42  ,      double(null)),
  MutationAssessor_pred             , iif(  a43  = '.', string(null), a43),
  FATHMM_score                      , dcast(a44  ,      double(null)),
  FATHMM_rankscore                  , dcast(a45  ,      double(null)),
  FATHMM_pred                       , iif(  a46  = '.', string(null), a46),
  MetaSVM_score                     , dcast(a47  ,      double(null)),
  MetaSVM_rankscore                 , dcast(a48  ,      double(null)),
  MetaSVM_pred                      , iif(  a49  = '.', string(null), a49),
  MetaLR_score                      , dcast(a50  ,      double(null)),
  MetaLR_rankscore                  , dcast(a51  ,      double(null)),
  MetaLR_pred                       , iif(  a52  = '.', string(null), a52),
  Reliability_index                 , dcast(a53  ,      uint8(null)),
  VEST3_score                       , dcast(a54  ,      double(null)),
  VEST3_rankscore                   , dcast(a55  ,      double(null)),
  PROVEAN_score                     , iif(  a56  = '.', string(null), a56),
  PROVEAN_converted_rankscore       , dcast(a57  ,      double(null)),
  PROVEAN_pred                      , iif(  a58  = '.', string(null), a58),
  CADD_raw                          , dcast(a59  ,      double(null)),
  CADD_raw_rankscore                , dcast(a60  ,      double(null)),
  CADD_phred                        , dcast(a61   ,     double(null)),
  GERPPP_NR                         , dcast(a62   ,     double(null)),
  GERPPP_RS                         , dcast(a63   ,     double(null)),
  GERPPP_RS_rankscore               , dcast(a64   ,     double(null)),
  phyloP46way_primate               , dcast(a65   ,     double(null)),  
  pyloP46way_primate_rankscore      , dcast(a66   ,     double(null)),     
  phyloP46way_placental             , dcast(a67   ,     double(null)), 
  phyloP46way_placental_rankscore   , dcast(a68   ,     double(null)),
  phyloP100way_vertebrate           , dcast(a69   ,     double(null)),  
  phyloP100way_vertebrate_rankscore , dcast(a70   ,     double(null)),
  phastCons46way_primate            , dcast(a71   ,     double(null)), 
  phastCons46way_primate_rankscore  , dcast(a72   ,     double(null)), 
  phastCons46way_placental          , dcast(a73   ,     double(null)), 
  phastCons46way_placental_rankscore, dcast(a74   ,     double(null)),
  phastCons100way_vertebrate        , dcast(a75   ,     double(null)), 
  phastCons100way_vertebrate_rankscore,   dcast(a76,    double(null)),
  SiPhy_29way_pi                    , iif(  a77   = '.', string(null), a77),
  SiPhy_29way_logOdds               , dcast(a78   ,     double(null)),
  SiPhy_29way_logOdds_rankscore     , dcast(a79   ,     double(null)),
  LRT_Omega                         , dcast(a80   ,     double(null)),
  UniSNP_ids                        , iif(  a81 = '.',  string(null), a81),
  KGp1_AC                           , dcast(a82   ,     int64(null)),
  KGp1_AF                           , dcast(a83   ,     double(null)),
  KGp1_AFR_AC                       , dcast(a84   ,     int64(null)),
  KGp1_AFR_AF                       , dcast(a85   ,     double(null)),
  KGp1_EUR_AC                       , dcast(a86   ,     int64(null)),
  KGp1_EUR_AF                       , dcast(a87   ,     double(null)),
  KGp1_AMR_AC                       , dcast(a88   ,     int64(null)),
  KGp1_AMR_AF                       , dcast(a89   ,     double(null)),
  KGp1_ASN_AC                       , dcast(a90   ,     int64(null)),
  KGp1_ASN_AF                       , dcast(a91   ,     double(null)),
  ESP6500_AA_AF                     , dcast(a92   ,     double(null)),
  ESP6500_EA_AF                     , dcast(a93   ,     double(null)),
  ARIC5606_AA_AC                    , dcast(a94   ,     int64(null)),
  ARIC5606_AA_AF                    , dcast(a95   ,     double(null)),
  ARIC5606_EA_AC                    , dcast(a96   ,     int64(null)),
  ARIC5606_EA_AF                    , dcast(a97   ,     double(null)),
  ExAC_AC                           , dcast(a98   ,     int64(null)),
  ExAC_AF                           , dcast(a99   ,     double(null)),
  ExAC_Adj_AC                       , dcast(a100   ,    int64(null)),
  ExAC_Adj_AF                       , dcast(a101   ,    double(null)),
  ExAC_AFR_AC                       , dcast(a102   ,    int64(null)),
  ExAC_AFR_AF                       , dcast(a103   ,    double(null)),
  ExAC_AMR_AC                       , dcast(a104   ,    int64(null)),
  ExAC_AMR_AF                       , dcast(a105   ,    double(null)),
  ExAC_EAS_AC                       , dcast(a106   ,    int64(null)),
  ExAC_EAS_AF                       , dcast(a107   ,    double(null)),
  ExAC_FIN_AC                       , dcast(a108   ,    int64(null)),
  ExAC_FIN_AF                       , dcast(a109   ,    double(null)),
  ExAC_NFE_AC                       , dcast(a110   ,    int64(null)),
  ExAC_NFE_AF                       , dcast(a111   ,    double(null)),
  null_SAS_AC                       , dcast(a112   ,    int64(null)),
  ExAC_SAS_AF                       , dcast(a113   ,    double(null)),
  clinvar_rs                        , iif(  a114   = '.', string(null), a114),
  clinvar_clnsig                    , dcast(a115   ,    int8(null)),
  clinvar_trait                     , iif(  a116   = '.', string(null), a116),
  COSMIC_ID                         , iif(  a117   = '.', string(null), a117),
  COSMIC_CNT                        , dcast(trim(a118, int_to_char(13)), int64(null))
  ),
  DBNSFP_V2p9_VARIANT
 ),  
 DBNSFP_V2p9_VARIANT
)"

delete_old_versions DBNSFP_V2p9_VARIANT
cleanup

log "Done"


