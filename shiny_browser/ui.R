# BEGIN_COPYRIGHT
# 
# Copyright © 2014 Paradigm4, Inc.
# This App is used in conjunction with the Community Edition of SciDB.
# SciDB is free software: you can redistribute it and/or modify it under the terms of the Affero General Public License, version 3, as published by the Free Software Foundation.
#
# END_COPYRIGHT 

library(shiny)
library(scidb)

shinyUI(fluidPage(
  
  # Application title
  titlePanel("1000G Browser"),
  
  # Sidebar with a slider input for the number of bins
  sidebarLayout(
    sidebarPanel(
      textInput("gene_symbol", "Gene Symbol", value = "ZMYND11"),
      actionButton("lookup_button", "Lookup Gene"),
      
      selectInput("chrom", 
                  label = "Chromosome",
                  choices = c("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "X", "Y", "MT"),
                  selected = "10"),
      
      numericInput("genomic_start", 
                   label = "Genomic Start Position", 
                   value = 180405),
      
      numericInput("genomic_end", 
                   label = "Genomic End Position", 
                   value = 300577),

      checkboxInput("compute_frequencies", "Do the AC Plot!", FALSE),
      actionButton("goButton", "Run query!"),
      sliderInput("num_vars", "Number of Variants to plot", 10, 200, value=10),
      sliderInput("ac_range", "AC Range", min = 0, max = 5008, value = c(0, 5008)),
      checkboxInput("ranges_only", "Show Only Non-SNP"),
      width=3
    ),
    
    mainPanel(
      htmlOutput("variantText"),
      plotOutput(outputId = "main_plot", height = "500px", width="1000px"),
      #ggvisOutput("ggvisPlot"),
      uiOutput("slider", inline=TRUE),
      width=9
    )
  )
))