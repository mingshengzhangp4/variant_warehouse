import re, sys


def gene_symbol_geneID_generator(inputFile, outputFile_tmp):
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

    fout = open(outputFile_tmp,'w')
    fout.write(headerLine)
    for aterm in symbol_map:
        wlist = [aterm] + symbol_map[aterm]
        fout.write('\t'.join(wlist) + '\n')
    fout.close()


def create_synonym2symbol(inputFile_tmp, outputFile):
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
    fin = open(inputFile_tmp, 'r')
    fout = open(outputFile, 'w')
    headerLine = fin.next()
    fout.write(headerLine)
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
          alist[0] = s
          hgnc_synonym = "|".join(list(syns))
          alist[5] = hgnc_synonym
          newLine = '\t'.join(alist) + '\n'
          fout.write(newLine)
    fin.close()
    fout.close()

def resolve_gene_symbol_collision(inputFile_with_collision, outputFile):
    fin=open(inputFile_with_collision, 'r')
    fout=open(outputFile, 'w')
    headerLine=fin.next()
    fout.write(headerLine)

    all_symbols = []
    collided_symbols=[]
    #line_no = 0
    for aline in fin:
        #line_no += 1
        #print line_no
        alist = [item.strip() for item in re.split('\t', aline)]
        symb = alist[0]
        if not symb in all_symbols:
            all_symbols.append(symb)
        else:
            #print "collision occurred!" 
            if not symb in collided_symbols:
                collided_symbols.append(symb)
    fin.seek(0)
    fin.next()
    for aline in fin:
        alist=[item.strip() for item in re.split('\t', aline)]
        if not alist[0] in collided_symbols:
            fout.write(aline)

    fin.seek(0)
    fin.next()
    coll_dict = {} ## {symbol0:[[entrezID1, ...], [hgnc_synonym1, ...]], symbol1:[[],[]], ....}
    for aline in fin:
        alist=[item.strip() for item in re.split('\t', aline)]
        s = alist[0]
        if s in collided_symbols:
            entrezID = alist[1]
            hgnc_synonyms = alist[5]
            if not s in coll_dict:
                coll_dict[s] = [[entrezID], [hgnc_synonyms]]
            else:
                coll_dict[s][0].append(entrezID)
                coll_dict[s][1].append(hgnc_synonyms)
    for sy in coll_dict:
        newLine_backbone = [item.strip() for item in re.split('\t', headerLine)]
        entrezList = coll_dict[sy][0]
        syn_list = coll_dict[sy][1]
        newLine_backbone[0] = sy
        newLine_backbone[1] = '&'.join(entrezList)
        newLine_backbone[5] = '&'.join(syn_list)
        newLine = '\t'.join(newLine_backbone) + '\n'
        fout.write(newLine)
 
    fin.close()
    fout.close()
    
        
if __name__=='__main__':
    
    #  inputFile = '/home/scidb/mzhang/variant_warehouse/load_gene_37/tcga_python_pipe/newGene.tsv'
    #  outputFile_tmp = '/home/scidb/mzhang/variant_warehouse/load_tcga/gene_tmp.tsv'
    #  outputFile_tmp2 = '/home/scidb/mzhang/variant_warehouse/load_tcga/gene_tmp2.tsv'   
    #  outputFile = '/home/scidb/mzhang/variant_warehouse/load_tcga/gene_symbol_as_id.tsv'
    inputFile = sys.argv[1]
    outputFile_tmp = sys.argv[2]
    outputFile_tmp2 = sys.argv[3]
    outputFile = sys.argv[4]
    gene_symbol_geneID_generator(inputFile, outputFile_tmp)
    create_synonym2symbol(outputFile_tmp, outputFile_tmp2)
    resolve_gene_symbol_collision(outputFile_tmp2, outputFile)

