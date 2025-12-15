
# Idaho County-Level Incidence Visualization App

##  Overview
This Shiny application provides an interactive dashboard to visualize the **number of reported cases** for various conditions across Idaho counties over time. Users can select a condition and a county to view yearly incidence trends from **2017 to 2025**.  
*Note: 2025 data is provisional and updated as of **November 30, 2025**.*

---

## Features
- **Interactive Selection**:
  - Choose a **condition** from the available list.
  - Choose a **county** within Idaho.
- **Dynamic Visualization**:
  - Displays a **bar chart** of yearly reported cases.
  - Highlights:
    - Bars for years with ≥5 cases.
    - Labels for years with **less than 5 cases** or **no reported cases**.
- **Provisional Data Note**:
  - Adds a footnote for 2025 data indicating its provisional status.

---

##  Data Source
- Input file: `IR_Data.csv`
- Expected columns:
  - `Condition`, `Date`, `County`, `County_Code`
- Data cleaning steps:
  - Standardizes condition names.
  - Removes irrelevant conditions.
  - Converts `Date` to proper format and extracts `Year`.
  - Adds Idaho state code (FIPS: 16).
  - Aggregates yearly incidence at the county level.

---

##  Dependencies
Ensure the following R packages are installed:

```r
tidycensus
tidyverse
httr
jsonlite
plotly
readxl
readr
lubridate
shiny
ggplot2
dply
