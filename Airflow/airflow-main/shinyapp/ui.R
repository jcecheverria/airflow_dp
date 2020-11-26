#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(plotly)
library(leaflet)
library(dplyr)

listapaises <- unique(confirmados$pais)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
    
    # Layout NAVBAR
    navbarPage("Covid-19",
               
               # SUMMARY METRICS
               tabPanel("Summary Metrics",
                        # Sidebar with a slider input for number of bins
                        sidebarLayout(
                          sidebarPanel(
                            radioButtons(
                              "summary_type",
                              "Valor",
                              choices = c("Casos Confirmados","Muertes","Recuperaciones"),
                              selected = c("Casos Confirmados")
                            ),
                            selectInput('paises', 'Paises', choices = listapaises,selected = c("Guatemala"), multiple = FALSE)
                          ),
                            
                            
                            mainPanel(
                              tabsetPanel(
                                tabPanel("Global",
                                         plotlyOutput("total_graph"),
                                         ),
                                tabPanel("By Country",
                                         plotlyOutput("country_graph")
                                         )
                              )
                              
                                )
                        )
                        ),
               
               # MAPAS
               tabPanel("Maps",
                 sidebarLayout(
                   sidebarPanel(
                     dateInput('date',
                               label = 'Fecha',
                               value = as.Date("2020-11-01")
                     ),
                     radioButtons(
                       "bubble_type",
                       "Valor",
                       choices = c("Casos Confirmados","Muertes","Recuperaciones"),
                       selected = c("Casos Confirmados")
                     )
                   ),
                   
                   mainPanel(
                     plotlyOutput("bubble")
                   )
                 )
               )
               )
))
