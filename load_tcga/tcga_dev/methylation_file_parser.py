# parse methylation data file and spit out TSV files for easy scidb loading

import re, sys

def methyl_parser(input_file):
    fin = open(input_file, 'r')
    fo_sample = open('methyl_sample_barcodes.txt', 'w')
    fo_gene = open('methyl_genes.txt', 'w')
    fo_probe = open('methyl_probe_data.txt', 'w')
    fo_methyl = open('methyl_data.txt', 'w')

    sample_line = fin.next()
    sample_list = [item.strip() for item in re.split('\t', sample_line)]
    uniq_sample = []  
    for i in range(1, len(sample_list), 4):
        uniq_sample.append(sample_list[i])
    
    fo_sample.write('\n'.join(uniq_sample))
    fo_sample.close()
    
    # skip the second line
    fin.next()

    gene_list = []
    for aline in fin:
        alist = [item.strip() for item in re.split('\t', aline)]
        gene_symbols = alist[2]
        if gene_symbols.lower() == 'na':
            continue
        # write probe-values for samples
        value_list =[]
        value_list.append(alist[0])
        for sample_index in xrange(1,len(alist), 4):
            value_list.append(alist[sample_index])
        fo_methyl.write('\t'.join(value_list) + '\n')                   


        # separate genes for a probe
        gene_symbols_list = [item.strip() for item in re.split(';', gene_symbols)]
        for gene_symbol in gene_symbols_list:
            gene_list.append(gene_symbol)
            probe_line = alist[0] + '\t' + gene_symbol + '\t' + alist[3] + '\t' + \
                         alist[4] + '\t' + alist[4] + '\t' + '|'.join(gene_symbols_list) + '\n'
            fo_probe.write(probe_line)
    gene_list = sorted(set(gene_list))
    fo_gene.write('\n'.join(gene_list))

    fo_methyl.close()
    fo_gene.close()
    fo_probe.close()      
    fin.close()

if __name__=='__main__':
    ## input_path = '/home/scidb/variant_warehouse/load_tcga/tcga_dev/tcga_download/gdac.broadinstitute.org_ACC.Merge_methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.Level_3.2015060100.0.0'
    ## methyl_file = 'ACC.methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.data.txt'
    ## input_file = input_path + '/' + methyl_file
    input_file = sys.argv[1]
    methyl_parser(input_file)
