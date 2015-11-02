
Sept-08, 2015

revised Sept-24, 2015
    -- To include entrez geneID as an attribute of a gene;
    -- solve the problem of gene symbol synonym ambiguilty


Paradigm4, waltham, MA

Customer Solution Group


This is a detailed descriptions on how to build a scidb database on TCGA data. Thad's java codes are used and modified whenever possible. But conquering codes for the pipe are in Python, rather than Perl, and the Derby and Hibernate components in Java codes are minimized, if not avoided completely.


---------------------
Data source and URLs
---------------------

--- ebi HGNC gene names---

**URL**

ftp.ebi.ac.uk/pub/databases/genomes/hgnc_complete_set.txt.gz

**fields(41)**

HGNC ID || Approved Symbol || Approved Name || Status || Locus Type || Locus Group || Previous Symbols || Previous Names || Synonyms ||	Name Synonyms || Chromosome || Date Approved || Date Modified || Date Symbol Changed || Date Name Changed || Accession Numbers || Enzyme IDs || Entrez Gene ID || Ensembl Gene ID || Mouse Genome Database ID || Specialist Database Links ||	Specialist Database IDs || Pubmed IDs || RefSeq IDs || Gene Family Tag || Gene family description || Record Type || Primary IDs || Secondary IDs || CCDS IDs ||	VEGA ID || Locus Specific Databases || Entrez Gene ID (supplied by NCBI) || OMIM ID (supplied by NCBI) || RefSeq (supplied by NCBI) || UniProt ID (supplied by UniProt) || Ensembl ID (supplied by Ensembl)	Vega ID (supplied by Vega)	UCSC ID (supplied by UCSC)	Mouse Genome Database ID (supplied by MGI)	Rat Genome Database ID (supplied by RGD)

HGNC:11998  ||    TP53  ||  tumor protein p53  ||     Approved  ||      gene with protein product ||      protein-coding gene  ||       ||        || p53, LFS1  ||     "Li-Fraumeni syndrome" || 17p13.1 || 1986-01-01 || 2015-09-01 ||      || 2008-01-16 || AF307851 ||    || 7157 || ENSG00000141510 || MGI:98834 || <!--,--> <!--,--> <!--,--> <!--,--> <!--,--> <!--,--> <!--,--> <!--,--> <!--,--> <!--,--> <a href="http://cancer.sanger.ac.uk/cosmic/gene/overview?ln=TP53">COSMIC</a><!--,--> <a href="http://www.orpha.net/consor/cgi-bin/OC_Exp.php?Lng=GB&Expert=120204">Orphanet</a><!--,--> <!--,--> <!--,--> <!--,--> <!--,--> <!--,--> || , , , , , , , , , , TP53, 120204, , , , , , || 6396087, 3456488, 2047879 || NM_000546 ||     ||          || Standard ||      ||       || CCDS11118, CCDS45605, CCDS45606, CCDS73963, CCDS73964, CCDS73965, CCDS73966, CCDS73967, CCDS73968, CCDS73969, CCDS73970, CCDS73971 || OTTHUMG00000162125 || "IARC TP53 Mutation Database|http://www-p53.iarc.fr/","p53 UMD TP53 mutation database|http://p53.fr/","Database of Germline p53 Mutations|http://www.lf2.cuni.cz/projects/germline_mut_p53.htm","MUTP53LOAD, Mutant p53 Loss Of Activity Database|http://www.umd.be:2072/","LRG_321|http://www.lrg-sequence.org/LRG/LRG_321" ||   7157 || 191170||  NM_001126115 || P04637 || ENSG00000141510 || OTTHUMG00000162125 || uc002gij.3 || MGI:98834 || RGD:3889






**notes**

Each synonym of the same entity gets a separate entry, and even withdrawn symbols keep their entries but flagged as such, and linked to related entries.


--- NCBI entrez gene names---

**URL**

ftp.ncbi.nlm.nih.gov/gene/DATA/GENE_INFO/mammalia/Homo_sapiens.gene_info.gz

**fields(14)**

tax_id || GeneID || Symbol || LocusTag || Synonyms || dbXrefs || chromosome || map_location || description || type_of_gene || Symbol_from_nomenclature_authority || Full_name_from_nomenclature_authority || Nomenclature_status || Other_designations || Modification_date



9606 || 7157 || TP53|| - || BCC7|LFS1|P53|TRP53 || MIM:191170|HGNC:HGNC:11998|Ensembl:ENSG00000141510|HPRD:01859|Vega:OTTHUMG00000162125 || 17 || 17p13.1 || tumor protein p53 || protein-coding || TP53 || tumor protein p53 || O || antigen NY-CO-13|mutant tumor protein 53|p53 tumor suppressor|phosphoprotein p53|transformation-related protein 53|tumor protein 53 || 20150830


**notes**

Each entity gets a single entry, and a single symbol is selected from all synonyms of this entity.


--- NCBI entrez gene names history---

**URL**

ftp.ncbi.nlm.nih.gov/gene/DATA/gene-history.gz


**fields(5)**

tax_id GeneID Discontinued_GeneID Discontinued_Symbol Discontinue_Date

jrivers@ubuntu1404vm:/development/javaworkspace/tcga_data$ cat gene_history |head -1
#Format: tax_id GeneID Discontinued_GeneID Discontinued_Symbol Discontinue_Date (tab is used as a separator, pound sign - start of a comment)

jrivers@ubuntu1404vm:/development/javaworkspace/tcga_data$ cat gene_history |grep TP53
9031	426399	427015	TP53I11	20120406
9606	8626	7160	TP53CP	20080819
9606	8626	8461	TP53L	20080817
9606	24150	51425	TP53TG3a	20050510
765952	-	10864742	TP53I3	20150205
1003195	-	11357328	TP53I	20150205
1234679	-	13990484	TP53I3	20150204



**notes**

Discontiuned_GeneID may map to none or a different GeneID. This info is useful when find genome coordinates for genes using gff3 file when it may still using a discontinued gene symbol/ID for a gene.



--- Sequence Ontology ref gene attributes on human genome builds---

**URL**

ftp.ncbi.nlm.nih.gov/genomes/H_sapiens/ARCHIVE/BUILD.37.3/GFF/ref_GRCh37.p5_top_level.gff3.gz


**fields(9)**

-see http://www.sequenceontology.org/gff3.shtml

seq_id source Type Start End Score Strand Phase(CDS) attributes

    attributes:
        ID, Name, Dbxref, gbkey, gene, gene_synonym

jrivers@ubuntu1404vm:/development/javaworkspace/tcga_data$ cat ref_GRCh37.p5_top_level.gff3 |grep -e 'RefSeq\sgene\s'|grep -e 'Name=TP53;'
NC_000017.10	RefSeq	gene	7571720	7590863	.	-	.	ID=gene27653;Name=TP53;Dbxref=GeneID:7157,HGNC:11998,HPRD:01859,MIM:191170;gbkey=Gene;gene=TP53;gene_synonym=FLJ92943,LFS1,P53,TRP53

jrivers@ubuntu1404vm:/development/javaworkspace/tcga_data$ cat ref_GRCh37.p5_top_level.gff3 |grep -e 'RefSeq\sgene\s'|head -5
NC_000001.10	RefSeq	gene	10954	11507	.	+	.	ID=gene0;Name=LOC100506145;Dbxref=GeneID:100506145;gbkey=Gene;gene=LOC100506145;pseudo=true
NC_000001.10	RefSeq	gene	12190	13639	.	+	.	ID=gene1;Name=LOC100652771;Dbxref=GeneID:100652771;gbkey=Gene;gene=LOC100652771
NC_000001.10	RefSeq	gene	14362	29370	.	-	.	ID=gene2;Name=WASH7P;Dbxref=GeneID:653635,HGNC:38034;gbkey=Gene;gene=WASH7P;gene_synonym=FAM39F,FLJ35264,FLJ50976,FLJ51139,FLJ99967,WASH5P;pseudo=true
NC_000001.10	RefSeq	gene	30366	30503	.	+	.	ID=gene3;Name=MIR1302-2;Dbxref=GeneID:100302278,HGNC:35294,miRBase:MI0006363;gbkey=Gene;gene=MIR1302-2;gene_synonym=hsa-mir-1302-2,MIRN1302-2
NC_000001.10	RefSeq	gene	34611	36081	.	-	.	ID=gene4;Name=FAM138A;Dbxref=GeneID:645520,HGNC:32334;gbkey=Gene;gene=FAM138A;gene_synonym=F379


**notes**

GFF3 is genome build specific. The gene coordinates in build 38 could be different from build 37, one expects GFF3 for build 37 could be different from build 38, especially for the gene coordinates. As the TCGA data still document the gene attributes according to genome build 37, we should be use the GFF3 of build 37 accordingly. For this reason, the gene name/symbol might not up-to-date. To update this info, the above-mentioned gene-history data have to be used for the mapping. Possible scienerio might look like this:

ref_GRCh37.p5_top_level.gff3 -> gene "LOC100652771" @coordinates (12190, 13639) -> gene_history -> 100287102 -> Homo_sapiens.gene_info -> (100287102, DDX11L1) [ -> ref_GRCh38.p*_top_level.gff3 -> 100287102 with possibly new coordinates ]

GFF3 include gene info at different level: gene, transcript, exon, CDS. For gene coordinate annotation, only need gene entries:
cat ref_GRCh37.p5_top_level.gff3|grep -e 'RefSeq\sgene\s'


--- TCGA mutation file MAF---

**URL**

http://gdac.broadinstitute.org/runs/stddata__20150601/data/BRCA/20150601/gdac.broadinstitute.org_BRCA.Mutation_Package_Calls.Level_3.2015060100.0.0.tar.gz


**fields(67)**

jrivers@ubuntu1404vm:~/Documents/tcga_mut/gdac.broadinstitute.org_BRCA.Mutation_Packager_Calls.Level_3.2015060100.0.0$ cat TCGA-PE-A5DE-01.maf.txt |head -1
Hugo_Symbol  ||	Entrez_Gene_Id	|| Center || NCBI_Build || Chromosome || Start_Position || End_Position ||	Strand || Variant_Classification || Variant_Type || Reference_Allele || Tumor_Seq_Allele1 || Tumor_Seq_Allele2 || dbSNP_RS || dbSNP_Val_Status || Tumor_Sample_Barcode || Matched_Norm_Sample_Barcode || Match_Norm_Seq_Allele1 || Match_Norm_Seq_Allele2 || Tumor_Validation_Allele1 || Tumor_Validation_Allele2 || Match_Norm_Validation_Allele1 || Match_Norm_Validation_Allele2 || Verification_Status || Validation_Status || Mutation_Status ||	Sequencing_Phase || Sequence_Source || Validation_Method || Score || BAM_File || Sequencer || Tumor_Sample_UUID || Matched_Norm_Sample_UUID || chromosome_name_WU || start_WU || stop_WU || reference_WU || variant_WU || type_WU || gene_name_WU || transcript_name_WU || transcript_species_WU || transcript_source_WU || transcript_version_WU || strand_WU || transcript_status_WU || trv_type_WU || c_position_WU || amino_acid_change_WU || ucsc_cons_WU || domain_WU || all_domains_WU || deletion_substructures_WU || transcript_error_WU || default_gene_name_WU || gene_name_source_WU || ensembl_gene_id || normal_ref_reads || normal_var_reads || normal_vaf || tumor_ref_reads || tumors_var_reads || tumor_vaf || EVS_EA || EVS_AA || EVS_All


jrivers@ubuntu1404vm:~/Documents/tcga_mut/gdac.broadinstitute.org_BRCA.Mutation_Packager_Calls.Level_3.2015060100.0.0$ cat TCGA-PE-A5DE-01.maf.txt |grep TP53
TP53 ||	0 || genome.wustl.edu || 37 || 17 || 7578423 || 7578423 || + ||	Missense_Mutation || SNP || C ||	C || T ||	||	|| TCGA-PE-A5DE-01A-11D-A27P-09 || TCGA-PE-A5DE-10A-01D-A27P-09 || C ||	C ||  ||  ||  ||   || Unknown || Untested || Somatic ||	Phase_IV || WXS || none || 1 ||	dbGAP || Illumina GAIIx || b59ec69e-e93a-4415-9c18-9d139b852919 || 7ff240ac-2b8f-4e5c-8184-980b3f9322a5 || 17 || 7578423 || 7578423 || C ||	T || SNP || TP53 || ENST00000269305 || human || ensembl || 69_37n || -1 || known || missense || c.507 || p.M169I1.000 || pfam_p53_DNA-bd,superfamily_p53-like_TF_DNA-bd,prints_p53_tumour_suppressor || pfam_p53_DNA-bd,pfam_p53_tetrameristn,pfam_p53_transactivation_domain,superfamily_p53-like_TF_DNA-bd,superfamily_p53_tetrameristn,prints_p53_tumour_suppressor || - || no_errors || TP53 || HGNC || ENSG00000141510 || 22 || 0 || 0.00 ||	28 || 9 || 24.32 || - || - || -


**notes**
- Hugo_Symbol is used, instead of HGNC_ID
- Entrez_gene_ID missing
- For each tumor sample, there would be multiple matching normal samples, and thus mutiple entries for a single tumor sample.






-------------------------
Java code base
-------------------------

---source code location---
mzhang@ubuntu1404vm:~$ svn checkout https://svn.scidb.net/poc/trunk poctrunk
$ cd ~/poctrunk/poc/TCGA/paradigm4_tcga/src


---compilation---

$ javac -Xlint -verbose -d /development/javaworkspace/tcga_classes -cp "/home/mzhang/poctrunk/poc/TCGA/paradigm4_tcga/lib/*" ./com/paradigm4/tcga/*.java com/paradigm4/tcga/dao/*.java ./com/paradigm4/tcga/domain/*.java ./com/paradigm4/tcga/fetch/*.java ./com/paradigm4/tcga/load/*.java ./com/paradigm4/load/parse/*.java ./com/paradigm4/tcga/load/parse/maf/*.java ./com/paradigm4/load/parse/maf2/*.java ./com/paradigm4/tcga/annovar/*.java

---run---


..fetch and unzip ebi/hugo gene name file..

java -Dsrc.url="ftp://ftp.ebi.ac.uk/pub/databases/genomes/hgnc_complete_set.txt.gz -Ddest.file="/development/javaworkspace/tcga_data/hgnc_complete_set.txt.gz" -DPARADIGM4.HOME="/home/mzhang/poctrunk/poc/TCGA/paradigm4_tcga" -classpath "/development/javaworkspace/tcga_classes:/home/mzhang/poctrunk/poctrunk/poc/TCGA/paradigm4_tcga/lib/*" com.paradigm4.tcga.fetch.FetchDataFile


..fetch and unzip ncbi entriz gene name file..

java -Dsrc.url="ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/GENE_INFO/mammalia/Homo_sapiens.gene_info.gz -Ddest.file="/development/javaworkspace/tcga_data


..fetch and unzip ncbi entriz gene history file..

java -Dsrc.url="ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/GENE_INFO/mammalia/gene_history.gz -Ddest.file="/development/javaworkspace/tcga_data/gene_history.gz" -DPARADIGM4.HOME="/home/mzhang/poctrunk/poc/TCGA/paradigm4_tcga" -classpath "/development/javaworkspace/tcga_classes:/home/mzhang/poctrunk/poctrunk/poc/TCGA/paradigm4_tcga/lib/*" com.paradigm4.tcga.fetch.FetchDataFile


..fetch and unzip ref_37_gff3 file..

java -Dsrc.url="ftp://ftp.ncbi.nlm.nih.gov/genomes/H_sapiens/ARCHIVE/BUILD.37.3/GFF/ref_GRCh37.p5_top_level.gff3.gz -Ddest.file="/development/javaworkspace/tcga_data/ref_GRCh37.p5_top_level.gff3.gz" -DPARADIGM4.HOME="/home/mzhang/poctrunk/poc/TCGA/paradigm4_tcga" -classpath "/development/javaworkspace/tcga_classes:/home/mzhang/poctrunk/poctrunk/poc/TCGA/paradigm4_tcga/lib/*" com.paradigm4.tcga.fetch.FetchDataFile


..fetch and unzip TCGA MAF file..

java -Dsrc.url="http://gdac.broadinstitute.org/runs/stddata__20150601/data/BRCA/20150601/gdac_broadinstitute.org_BRCA.Mutation_Package_Calls.Level_3.2015060100.0.0.tar.gz -Ddest.file="/development/javaworkspace/tcga_data/gdac_broadinstitute.org_BRCA.Mutation_Package_Calls.Level_3.2015060100.0.0.tar.gz" -DPARADIGM4.HOME="/home/mzhang/poctrunk/poc/TCGA/paradigm4_tcga" -classpath "/development/javaworkspace/tcga_classes:/home/mzhang/poctrunk/poctrunk/poc/TCGA/paradigm4_tcga/lib/*" com.paradigm4.tcga.fetch.FetchDataFile


-------------------
Generate gene table
-------------------

.. table fields ..
HGNC_symbol entrez_gene_ID gene_start(1) gene_end(1) strand(1) hgnc_synonyms(2) Synonyms dbXrefs cyto_genetic_loc Full_name_from_nomenclature_authority Type_of_gene chrom other_locations(1)

    all fields extracted from Homo_sapiens.gene_info (key:: $3/Symbol: SYMBOL), except:
    (1)  ref_GRCh37.p5_top_level.gff3 (Key:: $9/Attributes: Name=SYMBOL)
    (2)  hgnc_complete_set.txt (Key:: $2/Approved Symbol: SYMBOL)

.. scripting(python) ..
    - Parse ref_GRCh37.p5_top_level.gff3, create dict SYMBOL -> [strand, start, end, other_locations]
    - Parse hgnc_complete_set.txt, create dict SYMBOL -> hgnc_synonym
    - Parse Homo_sapiens.gene_info, and call the above two dicts, generate gene attribute file output
.. source file ..
   ~/poctrunk/poc/TCGA/paradigm4_tcga/tcga_python_pipe/create_gene_attributes.py
   or
   ~/Paradigm4_labs/variant_warehouse/load_gene_37/tcga_python_pipe/create_gene_attributes.py
   or
   http://github.com/Paradigm4/variant_warehouse/load_gene_37/tcga_python_pipe/create_gene_attributes.py
