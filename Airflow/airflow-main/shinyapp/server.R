#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(plotly)
library(leaflet)
library(dplyr)
library(RMySQL)
library(DBI)

dbcon <- dbConnect(MySQL(),
                   host="192.168.99.100",
                   port=3306,
                   user="test",
                   password = "test123",
                   dbname="test")

query_1 = "SELECT * FROM test.confirmados"
results_1 <- dbSendQuery(dbcon, query_1)
confirmados <- dbFetch(results_1)
dbClearResult(results_1)


query_1 = "SELECT * FROM test.muertos"
results_1 <- dbSendQuery(dbcon, query_1)
muertos <- dbFetch(results_1)
dbClearResult(results_1)


query_1 = "SELECT * FROM test.recuperados"
results_1 <- dbSendQuery(dbcon, query_1)
recuperados <- dbFetch(results_1)
dbClearResult(results_1)


# confirmados <- read.csv("confirmados.csv")
# muertos <- read.csv("muertos.csv")
# recuperados <- read.csv("recuperados.csv")

confirmados$date <- as.Date(with(confirmados, paste(year, month, day,sep="-")), "%Y-%m-%d")
muertos$date <- as.Date(with(muertos, paste(year, month, day,sep="-")), "%Y-%m-%d")
recuperados$date <- as.Date(with(recuperados, paste(year, month, day,sep="-")), "%Y-%m-%d")

confirmados_countries <- confirmados %>%
                            group_by(pais,lat,lon,year,month,day,date) %>% 
                            summarise(val = sum(val)) %>% ungroup()

muertos_countries <- muertos %>%
    group_by(pais,lat,lon,year,month,day,date) %>% 
    summarise(val = sum(val)) %>% ungroup()


recuperados_countries <- recuperados %>%
    group_by(pais,lat,lon,year,month,day,date) %>% 
    summarise(val = sum(val)) %>% ungroup()

confirmados_total <- confirmados %>% group_by(date) %>% summarise(val = sum(val)) %>% ungroup()
muertos_total <- muertos %>% group_by(date) %>% summarise(val = sum(val)) %>% ungroup()
recuperados_total <- recuperados %>% group_by(date) %>% summarise(val = sum(val)) %>% ungroup()



fig <- confirmados_total  %>% # filter(pais == "Guatemala") %>%
    plot_ly(x=~date,y=~val, mode = 'lines', text = paste("days from today"))

fig





# Define server logic required to draw a histogram
shinyServer(function(input, output) {

    output$distPlot <- renderPlot({

        # generate bins based on input$bins from ui.R
        x    <- faithful[, 2]
        bins <- seq(min(x), max(x), length.out = input$bins + 1)

        # draw the histogram with the specified number of bins
        hist(x, breaks = bins, col = 'darkgray', border = 'white')

    })
    
    output$bubble  <- renderPlotly({
        
        g <- list(showland = TRUE,landcolor = toRGB("gray95"))
        
        if(input$bubble_type=="Casos Confirmados"){
            bubble_selected_df <- confirmados_countries
            titulo_bubble <- "Confirmed per Country"
        }else if(input$bubble_type=="Muertes"){
            bubble_selected_df <- muertos_countries
            titulo_bubble <- "Deaths per Country"
        }else{
            bubble_selected_df <- recuperados_countries
            titulo_bubble <- "Recovered per Country"
        }
        
        df_plot <- bubble_selected_df %>%
                        filter(month == month(input$date)) %>% 
                        filter(day == day(input$date))
        
        fig <- plot_geo(df_plot, sizes = c(1, 1000))
        
        fig <- fig %>% add_markers(
            x = ~lon, y = ~lat, size = ~val, hoverinfo = "text",
            text = ~paste(df_plot$pais,"<br />",df_plot$val))
        
        fig <- fig %>%
            layout(title = titulo_bubble, geo = g)
        
        fig
        
    })
    
    output$total_graph <- renderPlotly({
        
        if(input$summary_type == "Casos Confirmados"){
            summary_selected_df <- confirmados_total
            titulo_summary <- "Global Confirmed"
        }else if(input$summary_type=="Muertes"){
            summary_selected_df <- muertos_total
            titulo_summary <- "Global Deaths"
        }else{
            summary_selected_df <- recuperados_total
            titulo_summary <- "Global Recovers"
        }
        
        
        
        fig <- summary_selected_df  %>%
            plot_ly(x=~date,y=~val, mode = 'lines')
        
        fig <- fig %>%
            layout(title = titulo_summary)
        
        fig
    })
    
    output$country_graph <- renderPlotly({
        
        if(input$summary_type == "Casos Confirmados"){
            summary_country_selected_df <- confirmados_countries
            titulo_summary_country <- "Country Confirmed"
        }else if(input$summary_type=="Muertes"){
            summary_country_selected_df <- muertos_countries
            titulo_summary_country <- "Country Deaths"
        }else{
            summary_country_selected_df <- recuperados_countries
            titulo_summary_country <- "Country Recovers"
        }
        
        
        fig <- summary_country_selected_df  %>% filter(pais == input$paises) %>%
            plot_ly(x=~date,y=~val, mode = 'lines')

        fig <- fig %>%
            layout(title = titulo_summary_country)
        
        fig
    })
    
    

})
