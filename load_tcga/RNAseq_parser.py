
import re, sys
def entrez_symbol_map(input):
    '''
    generate entrezID-geneSymbol map

    @para input: tsv file with unique entrez gene ID for entries
        (entrez_geneID:hgnc_symbol is 1:1 or 1:many), such as-
        /home/scidb/variant_warehouse/load_gene_37/tcga_python_pipe/newGene.tsv, with fields
        hgnc_symbol	entrez_geneID	Start	End	Strand	hgnc_synonym
	ncbi_synonym	dbXrefs	cyto_band	full_name	Type_of_gene
 	chromosome	other_locations
    @return a dictionary of {entrezID: geneSymbol}, which is 1-1
    '''
    fin = open(input, 'r')
    fin.next()
    entrez_symbol = {}
    for aline in fin:
        alist=[item.strip() for item in re.split('\t', aline)]
        entrezID = alist[1]
        if not entrezID in entrez_symbol:
            entrez_symbol[entrezID] = alist[0]
        else:
            continue
    return entrez_symbol

def parsing_RNAseq(RNAseq_file, entrez_symbol_map, current_wd):
    '''
    rewrite entrezID to geneSymbol

    @para RNAseq_file, with fields
        Hybridization REF       TCGA-3C-AAAU-01A-11R-A41B-07    TCGA-3C-AALI-01A-11R-A41B-07  ...
        gene_id                 normalized_count                normalized_count              ...
        ?|100130426             0.0000                           0.0000                       ...
        ADAMTS14|140766         75.4803                          123.9804                     ...
        ...........
    @para entrez_symbol_map, return from entrez_symbol_map(inputFile)  
    @return write out file with the same format as input RNAseq_file, with gene_id changed-
        Hybridization REF       TCGA-3C-AAAU-01A-11R-A41B-07    TCGA-3C-AALI-01A-11R-A41B-07  ...
        gene_id                 normalized_count                normalized_count              ...
        ADAMTS14                75.4803                          123.9804                     ...
        ...........
    '''
    fin = open(RNAseq_file, 'r')
    fout = open(current_wd + '/RNAseq_data.tsv', 'w')
    h1 = fin.next()
    h2 = fin.next()
    fout.write(h1 + h2)
    for aline in fin:
        alist = [item.strip() for item in re.split('\t', aline)]
        geneIDstring = alist[0]
        entrez_no = [item.strip() for item in re.split('\|', geneIDstring)][-1]
        if not entrez_no in entrez_symbol_map:
            continue
        else:
            gene_symbol = entrez_symbol_map[entrez_no]
            newList = [gene_symbol] + alist[1:]
            fout.write('\t'.join(newList) + '\n')

if __name__=='__main__':

    ## inputFile = '/home/scidb/variant_warehouse/load_gene_37/' + \
    ##            'tcga_python_pipe/newGene.tsv'

    RNAseq_file = sys.argv[1]
    gene_file = sys.argv[2]
    current_wd = sys.argv[3]
    ## RNAseq_file = '/home/scidb/variant_warehouse/load_tcga/tcga_dev/tcga_download/gdac.' + \
    ##               'broadinstitute.org_ACC.Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu' + \
    ##               '__Level_3__RSEM_genes_normalized__data.Level_3.2015060100.0.0/ACC' +\
    ##               '.rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes_normalized__data.data.txt'
    ## gene_file = '/home/scidb/variant_warehouse/load_gene_37/tcga_python_pipe/newGene.tsv'
    ## current_wd = '/home/scidb/variant_warehouse/load_tcga/tcga_dev'
  
    entrez_symbol = entrez_symbol_map(gene_file)
    ## print entrez_symbol
    parsing_RNAseq(RNAseq_file, entrez_symbol, current_wd)

