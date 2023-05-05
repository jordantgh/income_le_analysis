library(shiny)
library(ggplot2)
library(readr)
library(leaflet)
library(dplyr)
library(purrr)
g <- glue::glue

df <- read_csv(g(
    "{getOption('project_root')}/data/derived_tables/temp/final_imputed.csv"
))

# Define UI for application
ui <- fluidPage(
    titlePanel("Data Visualization"),
    sidebarLayout(
        sidebarPanel(
            selectInput("x_var",
                "X Variable:",
                choices = names(df[, -c(1:11, 75)]),
                selected = "cs_educ_ba"
            ),
            selectInput("y_var",
                "Y Variable:",
                choices = names(df[, -c(1:11, 75)]),
                selected = "bmi_obese_q1"
            ),
            radioButtons("level",
                "Level:",
                choices = c(
                    "county_name",
                    "cz",
                    "state"
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
                tabPanel("Bar Chart", plotOutput("barChart"))
            )
        )
    )
)

# Define server logic
server <- function(input, output) {
    output$scatterPlot <- renderPlot({
        ggplot(df, aes(x = !!sym(input$x_var), y = !!sym(input$y_var))) +
            geom_point(aes(color = !!sym(input$group_var)))
    })

    output$barChart <- renderPlot({
        ggplot(
            df[!is.na(df[[input$group_var]]), ],
            aes(x = !!sym(input$group_var),
            y = !!sym(input$y_var),
            group = !!sym(input$group_var))
        ) +
            geom_boxplot() +
            labs(x = "Region", y = "Current Smoking Rate (q1)")
    })
}


# Run the application
shinyApp(ui = ui, server = server)
