# parse cnv data file and spit out TSV files for easy scidb loading

import re, sys


def cnv_sample_parser(input_file):
    fin = open(input_file, 'r')
    fo_sample = open('cnv_sample_barcodes.txt', 'w')

    fin.next()  # header
    sample_list = []
    for aline in fin:
        alist = [item.strip() for item in re.split('\t', aline)]
        sample_list.append(alist[0])
    uniq_sorted_sample_list = sorted(set(sample_list))  
    fo_sample.write('\n'.join(uniq_sorted_sample_list))
    fo_sample.close()
    
    fin.close()


def gene_sorter(gene_file, field_idx, header=1):
    '''
    sort genes by left coordinate, chromosome-wisely
   
    @param gene_file: tsv file with required fields-
                      gene_symbol, chromosome, left_coordinate, right_coordinate
    @param field_idx: a tuple indexing the fields- 
                       gene_symbol, chromosome, left_coordinate, right_coordinate 
                       e.g. (0,-2,2,3)
    @return: a tuple of sorted list of tuples-
              (
                [(gene1.1, start_, end_), (gene1.2, start_, end_), ...],
                [(gene2.1, start_, end_), (gene2.2, start_, end_), ...],
                     ......
                [(gene23.1, start_, end_), (gene23.2, start_, end_), ...], # X-chrom
                [gene24.1, start_, end_), (gene24.2, start_, end_), ...]  # Y-chrom
              )
    '''
    fin = open(gene_file, 'r')
    if header:
        while header:
            fin.next()
            header -= 1 

    list_str = 25*'[],'
    list_str = list_str.strip(',')
    tuple_list_tuple = eval('(' + list_str + ')')

    for aline in fin:
        alist = [item.strip() for item in re.split('\t', aline)]
        if alist[field_idx[2]] in ['_', '0', '-'] or alist[field_idx[1]] in ['_', '0', '-']:
            continue
        gene_symbol = alist[field_idx[0]]
        chrom_str = alist[field_idx[1]]
        if chrom_str.lower() in ['x', 'x|y']:
            chrom_str = '23'
        if chrom_str.lower() == 'y':
            chrom_str = '24'
        if chrom_str.lower() == 'mt':
            chrom_str = '25'
        chrom = int(chrom_str)
        start_ = int(alist[field_idx[2]])
        end_ = int(alist[field_idx[3]])
        gene_tuple = (gene_symbol, start_, end_)
        tuple_list_tuple[chrom-1].append(gene_tuple)
        
    list_sortedList_tuple = eval('[' + list_str + ']')
    chr_index = 0
    for chrom_geneList in tuple_list_tuple:
        list_sortedList_tuple[chr_index] = sorted(\
            tuple_list_tuple[chr_index], key=lambda x:x[1])
        chr_index += 1

    fin.close()
    return list_sortedList_tuple

def left_gene_finder(sorted_gene_list, left_target):
    '''
    find the gene index close to the coordinate 'left_target'

    @param sorted_gene_list: a list of genes sorted by coordinates, like:
        [(gene0, 2033, 2980), (gene1, 34444, 89999), ..., (...)]
    @param left_target: left boundary for target segment window, like:
        34445555, which could fall into a gene or inter-gene space
    @return index into the input list of found gene
    '''
    nGenes = len(sorted_gene_list)
    working_window = [0, nGenes-1]
    while 1:
        left_bound_right_coord = sorted_gene_list[working_window[0]][2]
        right_bound_right_coord = sorted_gene_list[working_window[1]][2]
        right_bound_2right_coord = sorted_gene_list[working_window[1]-1][2]
        if left_target < left_bound_right_coord:
            return working_window[0]
        elif left_target > right_bound_right_coord:
            print 'No matched genes for this segment'
            return None
        elif left_target > right_bound_2right_coord:
            return working_window[1]

        else: ## move the window
            middle = int((working_window[0] + working_window[1])/2.0)
            middle_coord = sorted_gene_list[middle][2]
            if left_target < middle_coord:
                left_ = working_window[0]
                working_window = (left_, middle)
            else:
                right_ = working_window[1]
                working_window = (middle, right_)
     

def right_gene_finder(sorted_gene_list, start_pos, right_target):
    '''
    find the gene index close to the coordinate 'right_target'

    @param sorted_gene_list: a list of genes sorted by coordinates, like:
        [(gene0, 2033, 2980), (gene1, 34444, 89999), ..., (...)]
    @param start_pos: starting gene_idx as the window left bound,
                      returned from calling left_gene_finder(sorted_gene_list, left_target)
    @param right_target: right boundary for target segment window, like:
        34445555, which could fall into a gene or inter-gene space
    @return index into the input list of found gene
    '''

    if start_pos is None:
        return None
 

    nGenes = len(sorted_gene_list)
    working_window = [start_pos, nGenes-1]
    while 1:
        left_bound_2left_coord = sorted_gene_list[working_window[0]+1][1]
        right_bound_left_coord = sorted_gene_list[working_window[1]][1]
        if right_target < left_bound_2left_coord:
            return working_window[0]
        elif right_target > right_bound_left_coord:
            return working_window[1]
        else: ## move the window
            middle = int((working_window[0] + working_window[1])/2.0)
            middle_coord = sorted_gene_list[middle][2]
            if right_target < middle_coord:
                left_ = working_window[0]
                working_window = (left_, middle)
            else:
                right_ = working_window[1]
                working_window = (middle, right_)
 

def cnv_data_parser(input_file, gene_file, work_dir):
    '''
      parse cnv data file, and write out a tsv file for scidb loading

      @para input_file: tcga CNV file, with fields-
          Sample	Chromosome(1-23)	Start	End	Num_Probes	Segment_Mean
      @para gene_file: gene list file, such as:
          /home/mzhang/Paradigm4/variant_warehouse/load_gene_37/newGenes.txt, with required fields-
          gene_symbol, chrom, start_, end_
      @para work_dir: current working directory, such as
          /home/mzhang/Paradigm4_labs/variant_warehouse/load_tcga/tcga_dev
      @return null: write out the tsv file with fields-
                     sample_barcode       probe_name     Mean_value  reference_gene_symbol chromosome
          TCGA-OR-A5J1-10A-01D-A29K-01     'ACAA1'       -0.226          'ACAA'              17
          TCGA-OR-A5J1-10A-01D-A29K-01   'ACACA_MAX'     0.5517          'ACACA'             16
          TCGA-OR-A5J1-10A-01D-A29K-01   'ACACA_MIN'     0.1796          'ACACA'             16
          TCGA-OR-A5J1-10A-01D-A29K-01   '"RNVU1-1"'     0.5675          'RNVU1-1'            2
      '''


    list_sorted_geneList = gene_sorter(gene_file, (0, -2, 2, 3))
    fin = open(input_file, 'r')
    fout = open(work_dir + '/cnv_data.txt', 'w')
    headerLine = 'sample_barcode\tprobe_name\tMean_value\treference_gene_symbol\tchromosome\n'
    fout.write(headerLine)
    fin.next()

    sample_gene_vals = {}
     # {
     #  sample1: {gene1:[chrom, val1, val2...], gene2:[chrom, val1, val2, ...], ..., }
     #  sample2: {gene1:[chrom, val1, val2...], gene2:[chrom, val1, val2, ...], ..., }
     #      ........
     # }  
    for aline in fin:
        alist = [item.strip() for item in re.split('\t', aline)]

        sample_barcode = alist[0]
        if not sample_barcode in sample_gene_vals:
            sample_gene_vals[sample_barcode] = {}

        mean_val = float(alist[-1])
        chrom = int(alist[1])
        seg_left = int(alist[2])
        seg_right = int(alist[3])
        
        chrom_geneList = list_sorted_geneList[chrom-1]
        left_gene_index = left_gene_finder(chrom_geneList, seg_left)
        if left_gene_index is None:
            print 'no genes on this segment'
            continue
        right_gene_index = right_gene_finder(chrom_geneList, left_gene_index, seg_right)
        if right_gene_index is None:
            print 'something wrong, better check'
            continue
        mapped_gene_index = range(left_gene_index, right_gene_index+1)
        for i in mapped_gene_index:
            gene_symbol = chrom_geneList[i][0]
            if not gene_symbol in sample_gene_vals[sample_barcode]:
                sample_gene_vals[sample_barcode][gene_symbol] = [chrom, mean_val]
            else:
                sample_gene_vals[sample_barcode][gene_symbol].append(mean_val)
    for sample in sample_gene_vals:
        for gene in sample_gene_vals[sample]:
            if len(sample_gene_vals[sample][gene]) == 2:
                probe_name = gene
                Mean_value = sample_gene_vals[sample][gene][1]
                newLine = sample + '\t' + probe_name + '\t' + str(Mean_value) + \
                          '\t' + gene + '\t' + \
                          str(sample_gene_vals[sample][gene][0]) + '\n' 
                fout.write(newLine)
            else: # multiple vals
                max_value = max(sample_gene_vals[sample][gene][1:])
                min_value = min(sample_gene_vals[sample][gene][1:])
                max_line = sample + '\t' + gene + '_MAX' + '\t' +\
                           str(max_value) + '\t' + gene + '\t' +\
                           str(sample_gene_vals[sample][gene][0]) + '\n'
                min_line = sample + '\t' + gene + '_MIN' + '\t' +\
                           str(min_value) + '\t' + gene + '\t' +\
                           str(sample_gene_vals[sample][gene][0]) + '\n'
                fout.write(max_line + min_line)

    fin.close()

if __name__=='__main__':

    ## git_repo_base_path = '/home/mzhang/Paradigm4_labs/variant_warehouse'
    ## input_path = git_repo_base_path + '/' + 'load_tcga/tcga_dev/tcga_download/gdac.broadinstitute.org_ACC.Merge_snp__genome_wide_snp_6__broad_mit_edu__Level_3__segmented_scna_minus_germline_cnv_hg19__seg.Level_3.2015060100.0.0'
    ## cnv_file = 'ACC.snp__genome_wide_snp_6__broad_mit_edu__Level_3__segmented_scna_minus_germline_cnv_hg19__seg.seg.txt'
    ## input_file = input_path + '/' + cnv_file
    ## gene_file = git_repo_base_path + '/' + 'load_gene_37' + '/' + 'newGene.tsv'
    input_file = sys.argv[1]
    gene_file = sys.argv[2]
    work_dir = sys.argv[3]
    cnv_sample_parser(input_file)
    cnv_data_parser(input_file, gene_file, work_dir)
