box::use(
  shiny[...],
  shinydashboard[...],
  shinyWidgets[...],
  DBI[...],
  RSQLite[SQLite],
  ggplot2[...],
  plotly[...],
  readr[...],
  leaflet[...],
  leaflet.providers[...],
  dplyr[...],
  purrr[...],
  sf[...],
  ggbeeswarm[...],
  glue[g = glue],
  ggprism[...]
)

dir <- here::here()

# Establish a connection to the SQLite database
db <- dbConnect(SQLite(), g("{dir}/income_le.sqlite"))

# Read tables from the SQLite database
df_cty <- dbReadTable(db, "final_imputed_county")
df_cz <- dbReadTable(db, "final_imputed_cz")

# Disconnect from the SQLite database
dbDisconnect(db)

df_alt_names <- read_csv(
  g("{dir}/data/derived_tables/chetty_2016_covariate_names.csv")
)

alt_names_list <- setNames(
  df_alt_names$`Variable name`,
  df_alt_names$`Proposed name`
)

us_counties <- st_read(
  g("{dir}/data/external_data/shapefiles/county/co99_d00.shp")
)

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
        choices = alt_names_list[-(1:10)],
        selected = "cur_smoke_q1"
      ),
      selectInput(
        inputId = "y_var",
        label = "Y Variable:",
        choices = alt_names_list[-(1:10)],
        selected = "le_agg_q1"
      ),
      prettyRadioButtons(
        inputId = "level",
        label = "Level:",
        choices = alt_names_list[grep(
          "Commuting zone$|County$", names(alt_names_list)
        )],
        selected = "cz_name",
        shape = "round",
        bigger = TRUE,
        status = "primary"
      ),
      conditionalPanel(
        condition = "input.level == 'county_name'",
        prettyRadioButtons(
          inputId = "group_var",
          label = "Grouping Variable:",
          choices = c("Region", "intersects_msa"),
          selected = "Region",
          shape = "round",
          bigger = TRUE,
          status = "primary"
        )
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
      div(
        id = "dashboard-grid",
        box(
          plotlyOutput("scatterPlot",
            height = "100%",
            width = "100%"
          ),
          width = 12
        ),
        box(
          plotlyOutput("barChart",
            height = "100%",
            width = "100%"
          ),
          width = 12
        ),
        box(
          plotlyOutput("kernelDensity",
            height = "100%",
            width = "100%"
          ),
          width = 12
        ),
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


ui <- dashboardPage(header, sidebar, body, skin = "black")

server <- function(input, output) {
  selected_data <- reactive({
    if (input$level == "county_name") {
      return(df_cty)
    } else if (input$level == "cz_name") {
      return(df_cz)
    }
  })

  output$scatterPlot <- renderPlotly({
    p <- ggplot(
      selected_data()[!is.na(selected_data()[[
        if (input$level == "county_name") input$group_var else "Region"
      ]]), ],
      aes(x = !!sym(input$x_var), y = !!sym(input$y_var))
    ) +
      geom_point(aes(color = !!sym(
        if (input$level == "county_name") input$group_var else "Region"
      ))) +
      labs(
        x = names(keep(alt_names_list, \(x) x == input$x_var)),
        y = names(keep(alt_names_list, \(x) x == input$y_var))
      ) +
      theme_prism() +
      theme(text = element_text(size = 11,  family = "roboto"))

    ggplotly(p)
  })

  output$barChart <- renderPlotly({
    p <- ggplot(
      selected_data()[!is.na(selected_data()[[
        if (input$level == "county_name") input$group_var else "Region"
      ]]), ],
      aes(
        x = !!sym(
          if (input$level == "county_name") input$group_var else "Region"
        ),
        y = !!sym(input$y_var),
        group = !!sym(
          if (input$level == "county_name") input$group_var else "Region"
        )
      )
    ) +
      geom_violin() +
      geom_beeswarm(aes(color = !!sym(
        if (input$level == "county_name") input$group_var else "Region"
      ))) +
      labs(
        x = "Region",
        y = names(keep(alt_names_list, \(x) x == input$y_var))
      ) +
      theme_prism() +
      theme(text = element_text(size = 11,  family = "roboto"))

    ggplotly(p)
  })


  output$kernelDensity <- renderPlotly({
    p <- ggplot(selected_data()[!is.na(selected_data()), ]) +
      geom_histogram(aes(
        x = scale(!!sym(input$x_var)),
        fill = names(keep(alt_names_list, \(x) x == input$x_var))
      ), color = "black", bins = 30, alpha = 0.5) +
      geom_histogram(aes(
        x = scale(!!sym(input$y_var)),
        fill = names(keep(alt_names_list, \(x) x == input$y_var))
      ), color = "black", bins = 30, alpha = 0.5) +
      scale_fill_manual(
        name = "Variable",
        labels = c(
          names(keep(alt_names_list, \(x) x == input$x_var)),
          names(keep(alt_names_list, \(x) x == input$y_var))
        ),
        values = c("green", "red")
      ) +
      labs(
        x = "Standardized Value",
        y = "Count"
      ) +
      theme_prism() +
      theme(text = element_text(size = 11,  family = "roboto"))

    ggplotly(p) %>% layout(legend = list(
      x = 0.6, y = 1, font = list(size = 11)
    ))
  })




  color_scale <- reactive({
    colorNumeric(
      palette = "viridis",
      domain = scale(selected_data()[[input$y_var]])
    )
  })

  output$map <- renderLeaflet({
    df_geo <- selected_data()
    leaflet(df_geo) %>%
      addProviderTiles("CartoDB.Positron") %>%
      setView(lng = -95.583333, lat = 37.833333, zoom = 3) %>%
      addPolygons(
        fillColor = color_scale()(scale(df_geo[[input$y_var]])),
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
        values = scale(df_geo[[input$y_var]]),
        title = "Y Variable Value",
        position = "bottomright",
        labFormat = labelFormat(suffix = ""),
        opacity = 0.8
      )
  })
}

shinyApp(ui = ui, server = server)
