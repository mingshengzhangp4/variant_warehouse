
import re, sys
import gene_symbol_as_geneID as gsgid


def parsing_MIRNAseq(MIRNAseq_file, synonym_canonicalSymbol_map, current_wd):
    '''
    rewrite entrezID to geneSymbol

    @para MIRNAseq_file, with fields
    Hybridization REF  TCGA-OR-A5J1-01A-11R-A29W-13  TCGA-OR-A5J1-01A-11R-A29W-13  TCGA-OR-A5J1-01A-11R-A29W-13  TCGA-OR-A5J2-01A-11R-A29W-13 ...
    miRNA_ID                read_count              reads_per_million_miRNA_mapped       cross-mapped                read_count               ...
    hsa-let-7a-1             76213                         13484.031491                       N                         45441                 ...
     .......
    @para synonym_canonicalSymbol_map, return from function call of gsgid.create_synonym2symbol(gene_file)
  
    @return write out two files
        --output file1 --
          mirna_probe.tsv
          miRNA_probe_name miRNA_name canonical_name
          hsa-let-7a-1      LET7A-1    LET7A-1
          hsa-mir-551a      MIR551A    MIR551A
          hsa-mir-222       MIR222     MIR222A  [madeup]
          hsa-mir-222       MIR222     MIR222B  [madeup]
          ......

        --output file2 --
          mirna_data.tsv
        Hybridization REF  TCGA-OR-A5J1-01A-11R-A29W-13   TCGA-OR-A5J2-01A-11R-A29W-13            ...
        miRNA_ID            reads_per_million_miRNA_mapped      reads_per_million_miRNA_mapped    ...
        hsa-let-7a-1        13484.031491                              34.234                      ...
         .......
    '''
    fin = open(MIRNAseq_file, 'r')
    fout_probe = open(current_wd + '/mirna_probe.tsv', 'w')
    fout_data = open(current_wd + '/mirna_data.tsv', 'w')

    h1 = fin.next()
    h2 = fin.next()

    fout_probe.write('miRNA_probe_name\t' + 'miRNA_name\t' + 'canonical_name\n')
    for aline in fin:
        probe_name =[item.strip() for item in re.split('\t', aline)][0]
        probe_list = [item.strip().upper() for item in re.split('-', probe_name)]
        miRNA_name = probe_list[1] + '-'.join(probe_list[2:])
        try:
            canon_list = synonym_canonicalSymbol_map[miRNA_name]
            for canon in canon_list:
                fout_probe.write('\t'.join([probe_name, miRNA_name, canon]) + '\n')
        except:
            canonical_name = miRNA_name
            fout_probe.write('\t'.join([probe_name, miRNA_name, canonical_name]) + '\n')
   
    fin.seek(0)
    for aline in fin:
        alist = [item.strip() for item in re.split('\t', aline)]
        probe_id = alist[0]
        rpmm = [alist[i] for i in range(2, len(alist), 3)]
        fout_data.write('\t'.join([probe_id] + rpmm) + '\n')
    fin.close()
    fout_probe.close()
    fout_data.close()

if __name__=='__main__':
    MIRNAseq_file = sys.argv[1]
    gene_file = sys.argv[2]
    current_wd = sys.argv[3]
    ##  MIRNAseq_file = '/home/scidb/variant_warehouse/load_tcga/tcga_dev/tcga_download/' +\
    ##                  'gdac.broadinstitute.org_ACC.Merge_mirnaseq__illuminahiseq_' +\
    ##                  'mirnaseq__bcgsc_ca__Level_3__miR_gene_expression__data.Level_3.' +\
    ##                  '2015060100.0.0/ACC.mirnaseq__illuminahiseq_mirnaseq' +\
    ##                  '__bcgsc_ca__Level_3__miR_gene_expression__data.data.txt'
    ##  gene_file = '/home/scidb/variant_warehouse/load_gene_37/tcga_python_pipe/newGene.tsv'
    ##  current_wd = '/home/scidb/variant_warehouse/load_tcga/tcga_dev'
  
    synonym_canonicalSymbol = gsgid.create_synonym2symbol(gene_file)
    parsing_MIRNAseq(MIRNAseq_file, synonym_canonicalSymbol, current_wd)

