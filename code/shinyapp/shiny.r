library(shiny)
library(ggplot2)
library(readr)
library(leaflet)
library(leaflet.providers)
library(dplyr)
library(purrr)
library(sf)
g <- glue::glue

dir <- g("{getOption('project_root')}/data")
df_cty <- read_csv(g("{dir}/derived_tables/temp/final_imputed_county.csv"))
df_cz <- read_csv(g("{dir}/derived_tables/temp/final_imputed_cz.csv"))

us_counties <- st_read(g("{dir}/external_data/shapefiles/county/co99_d00.shp"))
us_cz <- st_read("data/external_data/shapefiles/cz/cz1990.shp")

us_counties <- us_counties %>%
    mutate(
        cty = as.numeric(paste0(STATE, COUNTY))
    )

df_cty <- left_join(us_counties, df_cty, by = "cty")
df_cz <- left_join(us_cz, df_cz, by = "cz")

ui <- fluidPage(
    titlePanel("Data Visualization"),
    sidebarLayout(
        sidebarPanel(
            selectInput("x_var",
                "X Variable:",
                choices = names(df_cty[, -c(1:11, 75)]),
                selected = "cs_educ_ba"
            ),
            selectInput("y_var",
                "Y Variable:",
                choices = names(df_cty[, -c(1:11, 75)]),
                selected = "bmi_obese_q1"
            ),
            radioButtons("level",
                "Level:",
                choices = c(
                    "cz",
                    "county_name"
                ),
                selected = "county_name"
            ),
            selectInput("group_var",
                "Grouping Variable:",
                choices = c(
                    "Region",
                    "intersects_msa"
                ),
                selected = "Region"
            )
        ),
        mainPanel(
            tabsetPanel(
                tabPanel("Scatter Plot", plotOutput("scatterPlot")),
                tabPanel("Bar Chart", plotOutput("barChart")),
                tabPanel("Map", leafletOutput("map"))
            )
        )
    )
)

server <- function(input, output) {
    selected_data <- reactive({
        if (input$level == "county_name") {
            return(df_cty)
        } else if (input$level == "cz") {
            return(df_cz)
        }
    })

    output$scatterPlot <- renderPlot({
        ggplot(
            selected_data(),
            aes(x = !!sym(input$x_var), y = !!sym(input$y_var))
        ) +
            geom_point(aes(color = !!sym(input$group_var)))
    })

    output$barChart <- renderPlot({
        ggplot(
            selected_data()[!is.na(selected_data()[[input$group_var]]), ],
            aes(
                x = !!sym(input$group_var),
                y = !!sym(input$y_var),
                group = !!sym(input$group_var)
            )
        ) +
            geom_boxplot() +
            labs(x = "Region", y = "Current Smoking Rate (q1)")
    })

    color_scale <- reactive({
        colorNumeric(
            palette = "viridis",
            domain = selected_data()[[input$y_var]]
        )
    })

    output$map <- renderLeaflet({
        df_geo <- selected_data()
        leaflet(df_geo) %>%
            addProviderTiles("CartoDB.Positron") %>%
            setView(lng = -95.583333, lat = 37.833333, zoom = 4) %>%
            addPolygons(
                fillColor = color_scale()(df_geo[[input$y_var]]),
                fillOpacity = 0.8,
                color = "#BDBDC3",
                weight = 1,
                opacity = 1,
                label = ~ g("{cz}, {stateabbrv}: {df_geo[[input$y_var]]}"),
                labelOptions = labelOptions(
                    style = list("font-weight" = "normal", padding = "3px 8px"),
                    textsize = "12px",
                    direction = "auto"
                ),
                highlightOptions = highlightOptions(
                    color = "#666",
                    weight = 2,
                    bringToFront = TRUE
                )
            ) %>%
            addLegend(
                pal = color_scale(),
                values = df_geo[[input$y_var]],
                title = "Y Variable Value",
                position = "bottomright",
                labFormat = labelFormat(suffix = ""),
                opacity = 0.8
            )
    })
}

shinyApp(ui = ui, server = server)
