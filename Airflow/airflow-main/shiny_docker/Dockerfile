FROM rocker/shiny

RUN R -e "install.packages(c('leaflet','plotly','dplyr','RMySQL','DBI','ggiraph','shinydashboard','ggplot2','readr','lubridate'))"

#COPY ./shinyapp /srv/shiny-server/