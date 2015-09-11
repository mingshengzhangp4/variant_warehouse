import re, os, subprocess

##  Sept 10, 2015
##  -------------------
##  Generate gene table
##  -------------------
##  
##  .. table fields ..
##  HGNC_symbol gene_start(1) gene_end(1) strand(1) hgnc_synonyms(2) Synonyms dbXrefs cyto_genetic_loc Full_name_from_nomenclature_authority Type_of_gene chrom other_locations(1)
##  
##      all fields extracted from Homo_sapiens.gene_info (key:: $3/Symbol: SYMBOL), except:
##      (1)  ref_GRCh37.p5_top_level.gff3 (Key:: $9/Attributes: Name=SYMBOL)
##      (2)  hgnc_complete_set.txt (Key:: $2/Approved Symbol: SYMBOL)
##  
##  .. scripting(python) ..
##      - Parse ref_GRCh37.p5_top_level.gff3, create dict SYMBOL -> [strand, start, end, other_locations]
##      - Parse hgnc_complete_set.txt, create dict SYMBOL -> hgnc_synonym
##      - Parse Homo_sapiens.gene_info, and call the above two dicts, generate gene attribute file output
 
# pull out only genes from gff3, which includes transcript, exon, cds etc as well.


def extract_export_entries(file_path='/development/javaworkspace/tcga_data', f_in = 'ref_GRCh37.p5_top_level.gff3', f_out = 'gff3_genes.txt', pattern = "RefSeq\sgene\s"):
    f_in_full_path = file_path + '/' + f_in
    f_out_full_path = file_path + '/' + f_out
    fout = open(f_out_full_path, "w")
    
    p1 = subprocess.Popen(["cat",  f_in_full_path], stdout=subprocess.PIPE)
    p2 = subprocess.Popen(["grep", "-e", pattern], stdin=p1.stdout, stdout=fout)
    p2.communicate()
    fout.close()


def parse_gff3():
    fin_full_path = '/development/javaworkspace/tcga_data/gff3_genes.txt'
    gene_coord_dict = {}
    dup_counts = 0
    with open(fin_full_path, 'r') as fin:
        for aline in fin:
            alist = [item.strip() for item in re.split('\t', aline)]
            #raw_input(alist)
            seqid = alist[0]

            ## parse chr ##
            if '23' in seqid:
                chr_ = 'X'
            elif '24' in seqid:
                chr_ = 'Y'
            elif '12920' in seqid:
                chr_ = 'MT'
            else:
                chr_ = seqid[7:9]
           
            strand_ = alist[6]
            start_ = alist[3]
            end_ = alist[4]
            attr_list = [attr.strip() for attr in re.split(';', alist[8])]
            #raw_input(attr_list)
            gene_name = attr_list[1][5:]
            #raw_input(gene_name)


            if  'NC_' in seqid:
                if not gene_name in gene_coord_dict:
                    other_locations = ''
                    gene_coord_dict[gene_name] = [strand_, start_, end_, other_locations]
                else:
                    newString =  chr_ + ':' + start_ + ':' + end_
                    currentLoc = gene_coord_dict[gene_name][3]
                    if currentLoc:
                        other_locations = currentLoc + '|' +  newString
                    else:
                        other_locations = currentLoc +  newString
                       
                    gene_coord_dict[gene_name][3] = other_locations
            else:
                dup_counts += 1
                print('duplicates discovered for : ' + gene_name)

            ## one gene with multiple mapping locations (thus mulitple entries in gff3) is caused by alternate reference loci, with seqid 'NW_*******', instead of 'NC_********', which is chosen when conflict occurs. Note also, un-placed seq with seqid 'NT_*****', the coordinates are relative to this scaffold, not the normal genomic coordinates, thus such entry should also be excluded. Another issue: homologous genes in X and Y (such as PAR genes), will have different coordinates on X or Y, and this should be flagged by adding a new field 'other_locations'. This situation may occur on other chromosomes as well.

    print('found duplicates: ' + str(dup_counts))
    print('Unique gene symbols: ' + str(len(gene_coord_dict)))
    return gene_coord_dict 

def parse_hgnc():
    fin_full_path = '/development/javaworkspace/tcga_data/hgnc_complete_set.txt'
    gene_hgncSynonym_dict = {}
    with open(fin_full_path, 'r') as fin:
        fin.next()
        for aline in fin:
            alist = [item.strip() for item in re.split('\t', aline)]
            #raw_input(alist)
            gene_symbol = alist[1]
            h_synonym = alist[8]
            if not h_synonym:
                h_synonym = '_'
            if not gene_symbol in gene_hgncSynonym_dict:
                gene_hgncSynonym_dict[gene_symbol] = (h_synonym)
            else:
                print('duplicates discovered for : ' + gene_symbol)
            #raw_input(gene_hgncSynonym_dict)
    return gene_hgncSynonym_dict 

def parse_hSapiens():
    fin_full_path = '/development/javaworkspace/tcga_data/Homo_sapiens.gene_info'
    gene_coord_dict = parse_gff3()
    gene_hSynonym_dict = parse_hgnc()
    fout = open('/development/javaworkspace/tcga_data/newGene.tsv','w')

    headerList = ['hgnc_symbol', 'Start', 'End', 'Strand', 'hgnc_synonym', 'ncbi_synonym', 'dbXrefs','cyto_band', 'full_name', 'Type_of_gene','chromosome', 'other_locations']
    headerLine = '\t'.join(headerList)
    fout.write(headerLine + '\n')
    with open(fin_full_path, 'r') as fin:
        fin.next()
        for aline in fin:
            alist = [item.strip() for item in re.split('\t', aline)]
            ##raw_input(alist)
            gene_symbol = alist[2]
            synonym = alist[4]
            if synonym == '-':
                synonym = '_'
            dbXrefs = alist[5]
            chrom = alist[6]
            cyto_band = alist[7]
            full_name = alist[11]
            type_of_gene = alist[9]


            try:
                strand_, start_, end_, other_locations = gene_coord_dict[gene_symbol]
                if not other_locations:
                    other_locations = '_'
            except:
                strand_ = '_'
                start_ = '_'
                end_ = '_'
                other_locations = '_'
            try:
                hgnc_synonym = gene_hSynonym_dict[gene_symbol]
            except:
                hgnc_synonym = '_'
            newList = [gene_symbol, start_, end_, strand_, hgnc_synonym,  synonym, dbXrefs, cyto_band, full_name, type_of_gene, chrom, other_locations]
            newLine = '\t'.join(newList)
            fout.write(newLine + '\n')
    fout.close()     

if __name__ == '__main__':
    #extract_export_entries()
    #parse_gff3()
    #parse_hgnc()
    parse_hSapiens()
