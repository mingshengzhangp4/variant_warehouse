import re, sys


def gene_symbol_geneID_generator(inputFile, outputFile):
    '''
    genenate gene list with gene_symbol as unique geneID

    @para inputFile: input tsv file with fields, which hgnc_symbol:entrez_geneID may be many-one-
        hgnc_symbol	entrez_geneID	Start	End	Strand	hgnc_synonym
	ncbi_synonym	dbXrefs	cyto_band	full_name	Type_of_gene
 	chromosome	other_locations
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
        
if __name__=='__main__':
    
    ## inputFile = '/home/scidb/variant_warehouse/load_gene_37/tcga_python_pipe/newGene.tsv'
    ## outputFile = '/home/scidb/variant_warehouse/load_tcga/tcga_dev/gene_symbol_as_id.tsv'
    inputFile = sys.argv[1]
    outputFile = sys.argv[2]
    gene_symbol_geneID_generator(inputFile, outputFile)
          
  

