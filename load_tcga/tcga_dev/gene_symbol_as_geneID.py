import re, sys


def gene_symbol_geneID_generator(inputFile, outputFile):
    '''
    genenate gene list with gene_symbol as unique geneID

    @para inputFile: input tsv file with fields, which hgnc_symbol:entrez_geneID may be many-one-
        hgnc_symbol	entrez_geneID	Start	End	Strand	hgnc_synonym
	ncbi_synonym	dbXrefs	cyto_band	full_name	Type_of_gene
 	chromosome	other_locations
        ABL1            25         133589268    133763062  +    JTK7, c-ABL, p150
        ABL|JTK7|bcr/abl|c-ABL|c-ABL1|p150|v-abl  MIM:189980|HGNC:HGNC:76|Ensembl:ENSG00000097007|HPRD:01809|Vega:OTTHUMG00000020813
        9q34.1  ABL proto-oncogene 1, non-receptor tyrosine kinase      protein-coding  9       _

    @para outputFile: output tsv file with the same fields as input file, but collapse entrez_geneID
        for a hgnc_symbol, making hgnc_symbol unique gene_id
    @ return none (write out output file)
    '''
    fin = open(inputFile, 'r')
    headerLine = fin.next()
    symbol_map = {}
    for aline in fin:
       alist=[item.strip() for item in re.split('\t', aline)]
       g_symbol = alist[0]
       entrez_id = alist[1]
       if not g_symbol in symbol_map:
           new_entrez_id = entrez_id
           symbol_map[g_symbol] = [new_entrez_id] + alist[2:]
       else:
           new_entrez_id = symbol_map[g_symbol][0] + '|' + entrez_id
           symbol_map[g_symbol] = [new_entrez_id] + alist[2:]
    fin.close()

    fout = open(outputFile,'w')
    fout.write(headerLine)
    for aterm in symbol_map:
        wlist = [aterm] + symbol_map[aterm]
        fout.write('\t'.join(wlist) + '\n')
    fout.close()


def create_synonym2symbol(inputFile):
    '''
    genenate a python dict mapping synonym to gene_symbols (one to one or one to many)

    @para inputFile: input tsv file with fields, which hgnc_symbol:entrez_geneID may be many-one-
        hgnc_symbol	entrez_geneID	Start	End	Strand	hgnc_synonym
	ncbi_synonym	dbXrefs	cyto_band	full_name	Type_of_gene
 	chromosome	other_locations
        ABL1            25         133589268    133763062  +    JTK7, c-ABL, p150
        ABL|JTK7|bcr/abl|c-ABL|c-ABL1|p150|v-abl  MIM:189980|HGNC:HGNC:76|Ensembl:ENSG00000097007|HPRD:01809|Vega:OTTHUMG00000020813
        9q34.1  ABL proto-oncogene 1, non-receptor tyrosine kinase      protein-coding  9       _
    @ return dict: 
        {syn0:[symbol0_0, symbol0_1, ...], syn1:[symbol1_0, symbol1_1, ...], ...,  ....}
    '''
    fin = open(inputFile, 'r')
    headerLine = fin.next()
    synonym2symbol = {}
    for aline in fin:
       alist=[item.strip() for item in re.split('\t', aline)]
       g_symbol = alist[0]
       h_syn = [item.strip().upper() for item in re.split(',', alist[5])]
       c_syn = [item.strip().upper() for item in re.split('\|', alist[6])]
       full_name = alist[9].upper().replace(" ", "_")
       syns = set(h_syn + c_syn + [g_symbol] + [full_name]) # throw-in the full name!
       if '_' in syns: syns.remove('_')
       if '-' in syns: syns.remove('-')
       for s in syns:
          if not s in synonym2symbol:
              synonym2symbol[s] = [g_symbol]
          else:
              # print "name collision."
              synonym2symbol[s].append(g_symbol)
    fin.close()
    return synonym2symbol
        
if __name__=='__main__':
    
    ## inputFile = '/home/scidb/variant_warehouse/load_gene_37/tcga_python_pipe/newGene.tsv'
    ## outputFile = '/home/scidb/variant_warehouse/load_tcga/tcga_dev/gene_symbol_as_id.tsv'
    inputFile = sys.argv[1]
    outputFile = sys.argv[2]
    gene_symbol_geneID_generator(inputFile, outputFile)
    gmap = create_synonym2symbol(inputFile)     
    # print gmap

