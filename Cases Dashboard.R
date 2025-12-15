


# Load necessary libraries
library(tidycensus)
library(tidyverse)
library(httr)
library(jsonlite)
library(plotly)
library(readxl)
library(readr)
library(lubridate)
library(shiny)
library(ggplot2)
library(dplyr)

# Read in the incidence rate data
data <- read_csv("IR_Data.csv")

# Replace specific condition names
data <- data %>%
  mutate(Condition = case_when(
    Condition == "Tuberculosis (2020 RVCT)" ~ "Tuberculosis",
    Condition %in% c("Salmonellosis (excl S. Typhi and S. Paratyphi)", 
                     "Salmonellosis 2018 (excl paratyphoid and typhoid)", 
                     "Salmonellosis - prior to 2018") ~ "Salmonellosis",
    TRUE ~ Condition
  ))

# Remove specified conditions
data <- data %>%
  filter(!Condition %in% c("2019-nCoV", "Amebiasis, NOS", "Congenital hypothyroidism", 
                           "Encephalitis, viral or aseptic", "Foodborne Illness, NOS", 
                           "Influenza Outbreak", "Streptococcal toxic-shock syndrome", 
                           "Waterborne Illness", "Aseptic meningitis", 
                           "Extraordinary occurrence of illness", 
                           "Hemolytic uremic synd,postdiarrheal", "Influenza", 
                           "Multisystem Inflammatory Syndrome in Children"))

# Convert Date column to Date-time format and extract the year
data$Date <- mdy_hm(data$Date)
data$Year <- year(data$Date)


# Define state code for Idaho (FIPS 16)
data$State_Code <- 16

# Calculate county-level yearly incidence
incidence_data <- data %>%
  group_by(Condition, Year, County, County_Code, State_Code) %>%
  summarise(Incidence = n(), .groups = "drop") %>%
  rename(GEOID = County_Code)


# Convert GEOID to character for consistency
incidence_data$GEOID <- as.character(incidence_data$GEOID)



# Get unique values from incidence data
unique_conditions <- unique(incidence_data$Condition)
unique_years <- unique(incidence_data$Year)
unique_counties <- unique(incidence_data[, c("GEOID", "County")])

# Create a complete grid of all combinations
complete_grid <- expand_grid(Condition = unique_conditions, 
                             Year = unique_years, 
                             unique_counties)

# Merge with incidence_data, filling missing Incidence values with 0
incidence_data_complete <- complete_grid %>%
  left_join(incidence_data, by = c("Condition", "Year", "GEOID", "County")) %>%
  mutate(Incidence = replace_na(Incidence, 0))


# Prepare final dataset for visualization
plot_data <- incidence_data_complete %>%
  select(Condition, Year, County, GEOID,  Incidence)

# Shiny UI
ui <- fluidPage(
  titlePanel("Number of Cases Reported"),
  sidebarLayout(
    sidebarPanel(
      selectInput("condition", "Select Condition", choices = unique(plot_data$Condition)),
      selectInput("county", "Select County", choices = unique(plot_data$County))
    ),
    mainPanel(
      plotlyOutput("bar_plot")
    )
  )
)

# Shiny Server
server <- function(input, output) {
  output$bar_plot <- renderPlotly({
    # Define the years range (2017-2025) to ensure they appear on the plot
    all_years <- tibble(Year = 2017:2025)
    
    filtered_data <- plot_data %>%
      filter(Condition == input$condition, County == input$county) %>%
      # Sum incidence for each year (ignoring duplicates)
      group_by(Year) %>%
      summarize(Incidence = sum(Incidence, na.rm = TRUE)) %>%
      ungroup()
    
    # Modify Year labels for 2025
    filtered_data$Year <- as.character(filtered_data$Year)
    filtered_data$Year[filtered_data$Year == "2025"] <- "2025*"  
    filtered_data$Year <- factor(filtered_data$Year, levels = c(as.character(2017:2024), "2025*"))
    
    
    p <- ggplot(filtered_data, 
                aes(x = Year, y = Incidence, 
                    text = paste("Number of Cases:", Incidence))) +
      
      # Bar layer
      geom_bar(data = filtered_data %>% filter(Incidence >= 5),
               stat = "identity", fill = "pink3", width = 0.6) +  
      
      # "Less than 5 cases reported" label
      geom_text(data = filtered_data %>% filter(Incidence < 5 & Incidence > 0),
                aes(x = Year, y = 0, label = "Less than 5\ncases reported"),
                vjust = 0, hjust = 1.5, size = 2, angle = 90, 
                color = "red4", fontface = "bold", family = "Verdana",
                inherit.aes = FALSE) +
      # "No reported cases" label
      geom_text(data = filtered_data %>% filter(Incidence == 0),
                aes(x = Year, y = 0, label = "No reported\ncases"),
                vjust = 0, hjust = 1.5, size = 2, angle = 90, 
                color = "red4", fontface = "bold", family = "Verdana",
                inherit.aes = FALSE) +
      
      scale_x_discrete(drop = FALSE) +  
      scale_y_continuous(limits = c(0, max(filtered_data$Incidence, na.rm = TRUE) + 1), 
                         expand = c(0.1, 0.1)) +  
      labs(title = paste("Number of Cases reported in", input$county, 
                         "for", input$condition),
           x = "", y = "Number of Cases Reported", fill = "Year") +  
      theme_classic() +
      theme(legend.position = "none",
            plot.title = element_text(size = 7, face = "bold"),
            text = element_text(family = "Verdana"))
    
    # Convert to interactive plotly plot with caption
    ggplotly(p, tooltip = "text") %>%
      layout(annotations = list(
        list(
          x = 0.5, y = -0.115,  
          text = "*2025 data as of 11/30/2025. 2025 data is provisional and may be subject to change.", 
          showarrow = FALSE, 
          xref = "paper", yref = "paper", 
          font = list(size = 11, color = "black", family = "Arial")
        )
      ))
  })
}

# Run the app
shinyApp(ui, server)




