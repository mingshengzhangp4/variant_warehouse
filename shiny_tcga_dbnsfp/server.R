# BEGIN_COPYRIGHT
# 
# Copyright © 2014 Paradigm4, Inc.
# This App is used in conjunction with the Community Edition of SciDB.
# SciDB is free software: you can redistribute it and/or modify it under the terms of the Affero General Public License, version 3, as published by the Free Software Foundation.
#
# END_COPYRIGHT 

library(shiny)
library(ggvis)
source("lof.R")

shinyServer(function(input, output, session) {
  lof_data <- reactive({
    input$goButton
    full_lof_query( isolate(input$tumor_list),
                    isolate(input$clin_regex),
                    isolate(input$gene_list),
                    isolate(input$kg_af_threshold),
                    isolate(input$score_type),
                    isolate(input$score_threshold)
                  )
  })
  
  output$output_text <- renderUI({
    res <- data.frame(lof_data()[1])
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
    result= data.frame(lof_data()[1])
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
  
  output$alterations_table <- renderDataTable({data.frame(lof_data()[1]) }, options = list(orderClasses = TRUE))
  output$fisher_test_table <- renderDataTable({data.frame(lof_data()[2]) }, options = list(orderClasses = TRUE))
  
  g <- reactive({
    x <- data.frame(lof_data()[2])
    i <- x$estimate>0 & x$estimate<Inf
    x <- x[i,]
    mx <- max(abs(log(x$estimate)))
    d <- data.frame(log_pvalue=-log(x$pval), log_odds=log(x$estimate))
    d$index <- sprintf("%s:%s",x$gene_1,x$gene_2)
    add_tooltip(
      scale_numeric(
        add_axis(
          layer_points(ggvis(d, ~log_odds, ~log_pvalue, key:=~index)),
          "y", title="- log(p value)"), "x", domain=c(-mx,mx)),
      html=function(x)x$index)
  })
  bind_shiny(g, "ggvisPlot", "ggvis_ui")
  
  output$networkPlot <- renderSimpleNetwork({
    p <- input$pval
    a <- data.frame(lof_data()[2])
    x <- a[a$pval < p, c(1,2,7)]
    
    edge_color = sapply(a[a$pval<p, 8],  FUN=function(x){ if(x<1) {"red"} else {"green"}})
    simpleNetwork(x[,1:2],
                  width=600,
                  height=800, 
                  linkDistance=100,
                  charge = -400,
                  fontSize=12, 
                  linkColour=edge_color)
  })
})
