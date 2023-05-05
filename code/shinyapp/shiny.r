library(shiny)
library(ggplot2)
library(readr)
library(leaflet)
library(dplyr)
library(purrr)
g <- glue::glue

# Load your data
# Simulate some data
set.seed(123)

# df <- data.frame(
#     cty = 1:100,
#     county_name = paste0("County", 1:100),
#     cty_pop2000 = sample(1000:5000, 100, replace = TRUE),
#     cz = sample(1:10, 100, replace = TRUE),
#     cz_name = paste0("CZ", sample(1:10, 100, replace = TRUE)),
#     cz_pop2000 = sample(5000:10000, 100, replace = TRUE),
#     statename = sample(c("State1", "State2", "State3"), 100, replace = TRUE),
#     state_id = as.numeric(factor(sample(
#         c(
#             "State1",
#             "State2",
#             "State3"
#         ),
#         100,
#         replace = TRUE
#     ))),
#     stateabbrv = substr(
#         sample(
#             c(
#                 "State1",
#                 "State2",
#                 "State3"
#             ),
#             100,
#             replace = TRUE
#         ),
#         1,
#         2
#     ),
#     region = sample(
#         c(
#             "Region1",
#             "Region2",
#             "Region3",
#             "Region4"
#         ),
#         100,
#         replace = TRUE
#     ),
#     cur_smoke_q1 = runif(100, 0, 1),
#     bmi_obese_q1 = runif(100, 20, 30),
#     cs00_seg_inc = rnorm(100, mean = 50000, sd = 10000),
#     adjmortmeas_amiall30day = rnorm(100, mean = 50, sd = 10),
#     cs_educ_ba = runif(100, 0, 1),
#     industry = sample(
#         c(
#             "Industry1",
#             "Industry2",
#             "Industry3",
#             "Industry4",
#             "Industry5"
#         ),
#         100,
#         replace = TRUE
#     )
# )


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
                choices = names(df[, -c(1:16, 74)]),
                selected = "cs_educ_ba"
            ),
            selectInput("y_var",
                "Y Variable:",
                choices = names(df[, -c(1:16, 74)]),
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
