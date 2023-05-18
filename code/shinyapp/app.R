box::use(
    shiny[...],
    shinydashboard[...],
    shinyWidgets[...],
    shinyjs[...],
    ggplot2[...],
    readr[...],
    leaflet[...],
    leaflet.providers[...],
    dplyr[...],
    purrr[...],
    sf[...],
    ggbeeswarm[...],
    glue[g = glue]
)

dir <- g("{getOption('project_root')}")
df_cty <- read_csv(g("{dir}/data/derived_tables/temp/final_imputed_county.csv"))
df_cz <- read_csv(g("{dir}/data/derived_tables/temp/final_imputed_cz.csv"))

us_counties <- st_read(g("{dir}/data/external_data/shapefiles/county/co99_d00.shp"))
us_cz <- st_read(g("{dir}/data/external_data/shapefiles/cz/cz1990.shp"))

us_counties <- us_counties %>%
    mutate(
        cty = as.numeric(paste0(STATE, COUNTY))
    )

df_cty <- left_join(us_counties, df_cty, by = "cty")
df_cz <- left_join(us_cz, df_cz, by = "cz")

# UI
header <- dashboardHeader(title = "Visualization")
sidebar <- dashboardSidebar(
    sidebarMenu(
        menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
        box(
            title = "Controls",
            status = "primary",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            selectInput(
                inputId = "x_var",
                label = "X Variable:",
                choices = names(df_cty[, -c(1:11, 75)]),
                selected = "cur_smoke_q1"
            ),
            selectInput(
                inputId = "y_var",
                label = "Y Variable:",
                choices = names(df_cty[, -c(1:11, 75)]),
                selected = "le_agg_q1"
            ),
            prettyRadioButtons(
                inputId = "level",
                label = "Level:",
                choices = c(
                    "cz",
                    "county_name"
                ),
                selected = "cz",
                shape = "round",
                bigger = TRUE,
                status = "primary"
            ),
            prettyRadioButtons(
                inputId = "group_var",
                label = "Grouping Variable:",
                choices = c(
                    "Region",
                    "intersects_msa"
                ),
                selected = "Region",
                shape = "round",
                bigger = TRUE,
                status = "primary"
            )
        )
    )
)

body <- dashboardBody(
    tags$head(
        includeCSS(g("{dir}/code/shinyapp/custom.css")),
    ),
    tabItems(
        tabItem(
            tabName = "dashboard",
            fluidRow(
                column(
                    width = 12,
                    box(
                        plotOutput("scatterPlot",
                            height = "100%",
                            width = "100%"
                        ),
                        width = 12
                    )
                ),
                column(
                    width = 12,
                    box(
                        plotOutput("barChart",
                            height = "100%",
                            width = "100%"
                        ),
                        width = 12
                    )
                ),
                column(
                    width = 12,
                    box(
                        leafletOutput("map",
                            height = "100%",
                            width = "100%"
                        ),
                        width = 12
                    )
                )
            )
        )
    )
)

ui <- dashboardPage(header, sidebar, body, skin = "black")

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
            geom_violin() +
            geom_beeswarm(aes(color = !!sym(input$group_var))) +
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

shinyApp(ui = ui, server = server) %>%
    shiny::runApp(port = 3838)
