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
library(dplyr)
library(RMySQL)
library(DBI)
library(lubridate)

dbcon <- dbConnect(MySQL(),
                   host="db",
                   port=3306,
                   user="test",
                   password = "test123",
                   dbname="test")

query_1 = "SELECT * FROM test.confirmados"
results_1 <- dbSendQuery(dbcon, query_1)
confirmados <- dbFetch(results_1, n=-1)
dbClearResult(results_1)

# confirmados <- read.csv("confirmados.csv")

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
                                         htmlOutput("global_total"),
                                         textOutput("warning_global")
                                         ),
                                tabPanel("By Country",
                                         plotlyOutput("country_graph"),
                                         htmlOutput("country_total"),
                                         textOutput("warning_country")
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
               ),
               
               # Tablas
               tabPanel("Tables",
                        sidebarLayout(
                          sidebarPanel(
                            radioButtons(
                              "table_type",
                              "Valor",
                              choices = c("Casos Confirmados","Muertes","Recuperaciones"),
                              selected = c("Casos Confirmados")
                            ),
                            selectInput('paises_table',
                                        'Paises',
                                        choices = listapaises,
                                        selected = c("Guatemala"), multiple = FALSE),
                            dateRangeInput("daterange", "Date range:",start = "2020-01-01")
                            
                          ),
                          mainPanel(dataTableOutput("table"))
                        ))
               )
))
