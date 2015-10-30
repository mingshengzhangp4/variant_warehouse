
import re, sys
import gene_symbol_as_geneID as gsgid


def parsing_protein(protein_file, synonym_canonicalSymbol_map, current_wd):
    '''
    rewrite entrezID to geneSymbol

    @para protein_file, with fields
    Sample REF                 TCGA-OR-A5J2-01A-21-A39K-20     TCGA-OR-A5J3-01A-21-A39K-20
    Composite Element REF        Protein Expression              Protein Expression 
    14-3-3_beta-R-V              0.22334275225                    -0.14206455625
    14-3-3_epsilon-M-C           -0.0195729252500001              -0.12290085275
    Acetyl-a-Tubulin-Lys40-R-C     0.0788483787499997             -0.10424065275
    ADAR1-M-V                      0.16202263575                  0.05806042625
    Annexin-1-M-E                  0.16743429375                  -0.0375481667499998
    ......

    @para synonym_canonicalSymbol_map, return from function call of gsgid.create_synonym2symbol(gene_file)
  
    @return write out a file
          protein_probe.tsv
          [ call gene_symbol_as_geneID.py for map for synonyms to gene_symbol ]
          probe_name       gene_name canonical_name
          14-3-3_beta-R-V   14-3-3_beta    14-3-3_beta
          ADAR1-M-V         ADAR1          ADAR1
          K7-M-E            K7             AK7  [madeup]
          K7-M-E            K7             AKA  [madeup]
          ......
    '''
    fin = open(protein_file, 'r')
    fout_probe = open(current_wd + '/protein_probe.tsv', 'w')

    h1 = fin.next()
    h2 = fin.next()

    fout_probe.write('probe_name\t' + 'gene_name\t' + 'canonical_name\n')
    for aline in fin:
        probe_name =[item.strip() for item in re.split('\t', aline)][0]
        probe_list = [item.strip().upper() for item in re.split('-', probe_name)]
        try:
            del probe_list[-1]
            del probe_list[-1]
        except:
            print 'exceptional probe name'
            # raw_input("check...")
        gene_name = '-'.join(probe_list)
        gen_list=[item.strip() for item in re.split('_', gene_name)]
        if len(gen_list) > 1:
            for ind in range(1, len(gen_list)):
                if gen_list[ind][0:2] in ['PT','PS','PY']:
                    gene_name = '_'.join(gen_list[0:ind])
        try:
            canon_list = synonym_canonicalSymbol_map[gene_name]
            for canon in canon_list:
                fout_probe.write('\t'.join([probe_name, gene_name, canon]) + '\n')
        except:
            canonical_name = gene_name
            fout_probe.write('\t'.join([probe_name, gene_name, canonical_name]) + '\n')
    fin.close()
    fout_probe.close()

if __name__=='__main__':
    protein_file = sys.argv[1]
    gene_file = sys.argv[2]
    current_wd = sys.argv[3]
    ##  protein_file = '/home/scidb/variant_warehouse/load_tcga/tcga_dev/tcga_download/' +\
    ##                  'gdac.broadinstitute.org_ACC.Merge_protein_exp__mda_rppa_core__mdanderson'+\
    ##                  '_org__Level_3__protein_normalization__data.Level_3.2015060100.0.0/'+\
    ##                  'ACC.protein_exp__mda_rppa_core__mdanderson_org__Level_3__protein'+\
    ##                  '_normalization__data.data.txt'
    ##  gene_file = '/home/scidb/variant_warehouse/load_gene_37/tcga_python_pipe/newGene.tsv'
    ##  current_wd = '/home/scidb/variant_warehouse/load_tcga/tcga_dev'
  
    synonym_canonicalSymbol = gsgid.create_synonym2symbol(gene_file)
    parsing_protein(protein_file, synonym_canonicalSymbol, current_wd)

