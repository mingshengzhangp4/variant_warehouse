# BEGIN_COPYRIGHT
# 
# Copyright © 2014 Paradigm4, Inc.
# This App is used in conjunction with the Community Edition of SciDB.
# SciDB is free software: you can redistribute it and/or modify it under the terms of the Affero General Public License, version 3, as published by the Free Software Foundation.
#
# END_COPYRIGHT 

library(shiny)
library(scidb)
library(reshape2)
library(ggplot2)
scidbconnect()

run_query = function( chromosome, start, end, compute_frequencies)
{
  validate(need(end >= start, 'Genomic end must exceed genomic start!'))
  validate(need(end - start <= 3000000, 'Genomic positions must differ by no more than 3 million. Select a smaller range!'))
  if( compute_frequencies == FALSE)
  {
    query= sprintf("
aggregate(
 apply(
  cross_join(
   between(KG_VARIANT, null, null, %i, null, null, %i, null, null), 
    filter(KG_CHROMOSOME, chromosome = '%s'), 
    KG_VARIANT.chromosome_id, KG_CHROMOSOME.chromosome_id
   ),
   start_val, start, end_val, end
 ),
 min(start_val) as start, max(end_val) as end, count(*) as num_variants
)",
      start, end, chromosome
    )
  }
  else
  {
    query = sprintf("
project(
   unpack(
    join(
     aggregate(
      apply( 
       aggregate(
        cross_join(
         cross_join(
          between(
           apply(
            KG_GENOTYPE, 
            ac, iif(allele_1, 1, 0) +  iif(allele_2, 1, 0)
           ),
           null, null, %i, null, null,
           null, %i, null,   null, null
          ),
          filter(KG_CHROMOSOME, chromosome = '%s'), 
          KG_GENOTYPE.chromosome_id,
          KG_CHROMOSOME.chromosome_id
         ),
         KG_POPULATION,
         KG_GENOTYPE.sample_id,
         KG_POPULATION.sample_id
        ),
        sum(ac) as ac, 
        chromosome_id, start, end, alternate_id, population_id
       ),
       --this is a bit of a collate coockalacka. It's probably better done in R but my R-foo is not strong enough yet
       ac0, iif(population_id =0, ac, null), 
       ac1, iif(population_id =1, ac, null),
       ac2, iif(population_id =2, ac, null),
       ac3, iif(population_id =3, ac, null),
       ac4, iif(population_id =4, ac, null)
      ),
      sum(ac0) as ac0, sum(ac1) as ac1, sum(ac2) as ac2, sum(ac3) as ac3, sum(ac4) as ac4,
      chromosome_id, start, end, alternate_id
     ),
     project(
      cross_join(
       between(
        KG_VARIANT,
        null, null, %i, null,
        null, %i, null,   null
       ),
       filter(KG_CHROMOSOME, chromosome = '%s'), 
       KG_VARIANT.chromosome_id,
       KG_CHROMOSOME.chromosome_id
      ), 
      reference, 
      alternate
     )
    ),
    n
   ),
   start, end, reference, alternate, ac0, ac1, ac2, ac3, ac4
  )", start, end, chromosome, start, end, chromosome
    )  
  }
    print("Running query")
    t1=proc.time()
    query_result = iqdf(query, n=100000)
    query_time = proc.time() -t1;
    print(query_time)
    if (compute_frequencies)
    {
      if(is.null(query_result))
      {
        query_result = data.frame(n=numeric(),
                                  start=numeric(),
                                  end=numeric(), 
                                  reference=character(),
                                  alternate=character(), 
                                  ac0=numeric(), ac1=numeric(),ac2=numeric(), ac3=numeric(),ac4=numeric())
      }
      query_result$total_ac = query_result$ac0+query_result$ac1+query_result$ac2+query_result$ac3+query_result$ac4
    }
    return(query_result)
}

shinyServer(function(input, output, session) {
  
  observeEvent(
    input$lookup_button,
    {
      symbol = input$gene_symbol
      query = sprintf("project(filter(GENE_37, gene='%s'), chromosome, start, end)", symbol)
      res = iqdf(query, n=1)
      if(is.null(res))
      {
        print("Couldn't find that gene, dude!")
        return()
      }
      #print(res)
      updateSelectInput(session, "chrom", selected = res$chromosome)
      updateNumericInput(session, "genomic_start", value=res$start)
      updateNumericInput(session, "genomic_end", value=res$end)
    }
  )

  query_result = reactive(
    { 
      input$goButton
      run_query(isolate(input$chrom), isolate(input$genomic_start), isolate(input$genomic_end), input$compute_frequencies)
    }
  )
  
  output$slider <- renderUI({
    res <- query_result()
    min_ac = input$ac_range[1]
    max_ac = input$ac_range[2]
    if(nrow(res)>=1 && input$compute_frequencies == TRUE)
    {
      if ( input$ranges_only )
      {
        res = subset(res, start!=end)
      }
      res = subset(subset(res, total_ac>=min_ac), total_ac<=max_ac)
      num_vars_in_range = nrow(res)
      sliderInput("position_slider", "scroll", min=1, max=num_vars_in_range, value=1, step=1) 
    }
    else
    {
      sliderInput("position_slider", "scroll", min=1, max=1, value=1, step=1) 
    }
  })
  
  output$variantText <- renderUI({
    res <- query_result()
    if ( input$ranges_only )
    {
      res = subset(res, start!=end)
    }
    if (input$compute_frequencies == FALSE)
    {
      result = sprintf("              
<table>
<tr> <td>Variants reutrned by query:&nbsp;</td> <td>%i</td>        </tr>
<tr> <td>Start of Range:&nbsp;</td>             <td>%i</td>        </tr>
<tr> <td>End of Range:&nbsp;</td>             <td>%i</td>        </tr>
</table><br/>", 
      res$num_variants[1], res$start, res$end)
      return(HTML(result))
    }
    total_vars = nrow(res)
    min_ac = input$ac_range[1]
    max_ac = input$ac_range[2]
    res = subset(subset(res, total_ac>=min_ac), total_ac<=max_ac)
    num_vars_in_range = nrow(res)
    if(num_vars_in_range == 0)
    {
      result = sprintf("
<table>
<tr> <td>Variants reutrned by query:&nbsp;</td> <td>%i</td>        </tr>
<tr> <td>Variants in AC Range:&nbsp;</td>       <td>%i</td>        </tr>
</table><br/>
[NO DATA TO DISPLAY]", 
                     total_vars, num_vars_in_range)  
      return(HTML(result))
    }
    plot_position = input$position_slider
    if (is.null(plot_position))
    {
      plot_position = 1
    }
    num_vars_to_show = max(min(input$num_vars-1, nrow(res)-plot_position), 0)
    res2 = res[plot_position : (plot_position+num_vars_to_show),]      
    min_pos = res2[1,]$start
    max_pos = res2[nrow(res2),]$start
 
#hashtag lazy
    result = sprintf("
<table>
<tr> <td>Total samples:&nbsp;</td>              <td>2504</td>      </tr>
<tr> <td>Total variants:&nbsp;</td>             <td>81717067</td>  </tr>
<tr> <td>Variants reutrned by query:&nbsp;</td> <td>%i</td>        </tr>
<tr> <td>Variants in AC Range:&nbsp;</td>       <td>%i</td>        </tr>
<tr> <td>Variants displayed:&nbsp;</td>         <td>%i</td>        </tr>
<tr> <td>Positions displayed:&nbsp;</td>        <td>[%i : %i]</td> </tr>
</table>", 
                     total_vars, num_vars_in_range, num_vars_to_show+1, min_pos, max_pos)  

    return(HTML(result))
  })
  
  output$main_plot <- renderPlot(height=500, width=1000, expr =
  {
    res <- query_result()
    if ( input$ranges_only )
    {
      res = subset(res, start!=end)
    }
    min_ac = input$ac_range[1]
    max_ac = input$ac_range[2]
    if ( input$compute_frequencies)
    {    
      res = subset(subset(res, total_ac>=min_ac), total_ac<=max_ac)
    }
    plot_position = input$position_slider
    num_vars_to_show = max(min(input$num_vars -1, nrow(res)-plot_position), 0)
    #Error handling: this thing really doesn't like NA or empty data frames.
    if (is.null(plot_position))
    {
        plot_position = 1
    }
    if(nrow(res) == 0 || plot_position > nrow(res) || input$compute_frequencies == FALSE)
    {
       res = data.frame(start=0,end=0, reference='N', alternate='N', ac0=0,ac1=0,ac2=0,ac3=0,ac4=0,total_ac=0)
       plot_position = 1
       num_vars_to_show = 0
       return()
    }
    res2 = res[plot_position : (plot_position + num_vars_to_show), ]
    res2$variant = substr(ifelse( res2$start != res2$end, 
                                    sprintf("%i:%i %s - %s", res2$start, res2$end, res2$reference, res2$alternate), 
                                    sprintf("%i %s - %s", res2$start, res2$reference, res2$alternate)
                             ),1, 29)
    res2 = data.frame(res2$variant, res2$ac0, res2$ac1, res2$ac2, res2$ac3, res2$ac4)
    colnames(res2) = c("variant", "AFR", "AMR", "EAS", "EUR", "SAS")
    res2 = melt(res2, id.vars="variant", variable.name="population", value.name="AC")
    if(num_vars_to_show > 30)
    {
      fs=0
    }
    else
    {
      fs=12
    }
    plot_1 = ggplot(res2) + 
             theme_bw() + 
             geom_bar(aes(x=variant, fill=population, y=AC), stat="identity", width=0.95, colour="black") + 
             theme(axis.text.x=element_text(angle = 45, size=fs, color="black", hjust=1)) + 
             theme(axis.text.y=element_text(size=12, color="black")) +
             scale_fill_manual(values = c("#2177b3", "#fa7f1c", "#2b9f2b", "#d52727","#9668c0"))
             
    print(plot_1)
  })
})

