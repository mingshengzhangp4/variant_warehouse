# BEGIN_COPYRIGHT
# 
# Copyright © 2014 Paradigm4, Inc.
# This App is used in conjunction with the Community Edition of SciDB.
# SciDB is free software: you can redistribute it and/or modify it under the terms of the Affero General Public License, version 3, as published by the Free Software Foundation.
#
# END_COPYRIGHT 

source("lof.R")
library(ggvis)
library(networkD3)

gene.symbol = iqdf(GENE$gene_symbol, n=Inf)$gene_symbol
tumor.type = iqdf(TUMOR_TYPE$tumor_type_name, n=Inf)$tumor_type_name
scores     = iqdf("project(filter(attributes(DBNSFP_V2p9_VARIANT), regex(name, '.*score')), name, type_id)")$name

shinyUI(fluidPage(
  
  # Application title
  titlePanel("TCGA alterations filtered using dbNSFP scores"),
  
  # Sidebar with a slider input for the number of bins
  sidebarLayout(
    sidebarPanel(
      selectInput('tumor_list', 'Tumor Types', tumor.type, multiple=TRUE, selectize=TRUE, 
                  selected=c("BRCA")),
      selectInput('gene_list',  'Genes',       gene.symbol, multiple=TRUE, selectize=TRUE, 
                  selected=c('DCK', 'RNR1' , 'RNR2', 'RNR3', 'RNR4', 'RNR5', 'SLC29A1', 'SLC29A2', 'SLC29A3', 'NOTCH1', 'NOTCH2')
      ),
      textInput  ('clin_regex', 'Clinical match'),
      sliderInput('kg_af_threshold', '1000G Max AF', min=0, max=1, step=0.01, value=0.1),
      selectInput('score_type',  'dbNSFP score',  scores, multiple=FALSE, selectize=TRUE, 
                  selected="SIFT_converted_rankscore"),
      sliderInput('score_threshold', 'Score Min Threshold', min=0, max=1, step=0.01, value=0.55),
      actionButton("goButton", "Run query!"),
      selectInput('plot_style', 'Plot style', c('tumor / gene', 'sample / gene'), selected = 'tumor / gene'),
      width=4
     ),
     mainPanel(
      tabsetPanel( 
       id = "tabset",
       tabPanel('Plot',
        htmlOutput("output_text"),
        plotOutput(outputId = "main_plot", height = "700px")
       ),
       tabPanel('Alterations Data',
        dataTableOutput('alterations_table')
       ),
       tabPanel('Fisher Test Data',
        dataTableOutput('fisher_test_table')
       ),
       tabPanel('Fisher Volcano',
        ggvisOutput('ggvisPlot')
       ),
       tabPanel('Fisher Network',
        simpleNetworkOutput('networkPlot'),
        sliderInput('pval', label = 'p value threshold', min = 0.0005, max = 0.2, step = 0.0005, value = 0.001)
       )),
       width = 8
     )
   )
  )
)
