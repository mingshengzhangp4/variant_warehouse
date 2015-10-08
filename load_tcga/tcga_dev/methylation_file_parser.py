# parse methylation data file and split out TSV files for easy scidb loading

import re

def methyl_parser(input_file):
    fin = open(input_file, 'r')
    fo_sample = open('methyl_sample_barcodes.txt', 'w')
    fo_gene = open('methyl_genes.txt', 'w')
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
        gene_symbol = alist[2]
        if gene_symbol.lower()== 'na':
            continue
        gene_list.append(gene_symbol)
        beta_values = []
        beta_values.append(gene_symbol)
        for i in range(1, len(alist), 4):
            beta_values.append(alist[i])
        fo_methyl.write('\t'.join(beta_values) + '\n')
        
    fo_gene.write('\n'.join(gene_list))

    fo_methyl.close()
    fo_gene.close()       
    fin.close()

if __name__=='__main__':
    input_path = '/home/scidb/variant_warehouse/load_tcga/tcga_dev/tcga_download/gdac.broadinstitute.org_ACC.Merge_methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.Level_3.2015060100.0.0'
    methyl_file = 'ACC.methylation__humanmethylation450__jhu_usc_edu__Level_3__within_bioassay_data_set_function__data.data.txt'
    input_file = input_path + '/' + methyl_file
    methyl_parser(input_file)
