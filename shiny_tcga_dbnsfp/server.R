# BEGIN_COPYRIGHT
# 
# Copyright © 2014 Paradigm4, Inc.
# This App is used in conjunction with the Community Edition of SciDB.
# SciDB is free software: you can redistribute it and/or modify it under the terms of the Affero General Public License, version 3, as published by the Free Software Foundation.
#
# END_COPYRIGHT 

library(shiny)
source("lof.R")

shinyServer(function(input, output, session) {
  lof_data <- reactive({
    input$goButton
    get_lof_data( isolate(input$tumor_list),
                  isolate(input$clin_regex),
                  isolate(input$gene_list),
                  isolate(input$kg_af_threshold),
                  isolate(input$score_type),
                  isolate(input$score_threshold)
                  )
  })
  
  output$output_text <- renderUI({
    res <- lof_data()
    result = sprintf("
Total alterations: %i, Samples: %i, Unique alterations: %i
<br/>
<table>",   nrow(res), length(unique(res$sample)), length(unique(res$variant)))
    summary = data.frame(table(res[c("tumor")]))
    result = sprintf("%s %s", result, paste(sprintf("<tr> <td> %s:&nbsp;</td> <td>%i</td></td>", summary[,1], summary[,2]), collapse=" "))
    result = sprintf("%s </table>", result)
    return(HTML(result))
  })
  
  output$main_plot <- renderPlot({
    result= lof_data()
    if (input$plot_style == "sample / gene")
    {
      reduced = data.frame(table(result[c("sample","gene")]))
      ggplot(data = reduced)  + theme_bw() +aes(y=sample, x=gene, fill=Freq) + geom_tile()  
    }
    else if (input$plot_style == "tumor / gene")
    {
      reduced = data.frame(table(result[c("tumor","gene")]))
      if(length(unique(reduced$tumor)) > 1)
      {
        ggplot(data = reduced) + theme_bw() + aes(y=tumor, x=gene, fill=Freq) + geom_tile()  
      }
      else
      {
        ggplot(data = reduced) + theme_bw() + aes(x=gene, y=Freq, fill=Freq) + geom_bar(stat="identity", width=0.95)
      }
    }
  })
  
})