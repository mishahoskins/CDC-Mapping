


install.packages(c("sf", "ggplot2", "dplyr", "tigris", "viridis"))

library(sf)
library(ggplot2)
library(dplyr)
library(tigris)
library(viridis)

county_level <- read.csv("C:\\Data\\Injury and Violence CDC Data Zip\\Injury and Violence CDC Data Zip\\Mapping_Injury__Overdose__and_Violence_-_County_20250131.csv")  

nc_county_level <- county_level %>% 
  filter(ST_NAME == "North Carolina")
head(nc_county_level)

nc_county_level$GEOID_new <- as.character(nc_county_level$GEOID)  # Ensure GEOID is character for merging

sum(is.na(nc_county_level$GEOID))  # Check for missing GEOID values

# Clean and convert the 'Year' column in the 'county_level' dataset
nc_county_level$Year <- gsub("[^0-9]", "", nc_county_level$Period)  # Clean the column (remove non-numeric characters)
nc_county_level$Year <- as.numeric(nc_county_level$Period)  # Convert it to numeric

# Filter out rows where 'Year' is missing (NA)
nc_county_level <- nc_county_level %>% 
  filter(!is.na(Year))

# Check if the conversion worked
summary(nc_county_level$Year)



homicide_data <- nc_county_level %>% filter(Intent == "All_Homicide")
suicide_data <- nc_county_level %>% filter(Intent == "All_Suicide")
drugOD_data <- nc_county_level %>% filter(Intent == "Drug_OD")
firearmALLdeath_data <- nc_county_level %>% filter(Intent == "FA_Deaths")
firearmhomicide_data <- nc_county_level %>% filter(Intent == "FA_Homicide")
firearmsuicide_data <- nc_county_level %>% filter(Intent == "FA_Suicide")


head(homicide_data)
head(suicide_data)
head(drugOD_data)
head(firearmALLdeath_data)
head(firearmhomicide_data)
head(firearmsuicide_data)


# Load county-level shapefile for the entire US
counties_sf <- counties(cb = TRUE)

# Filter the counties_sf to include only North Carolina (FIPS code "37")
nc_counties_sf <- counties_sf %>% 
  filter(STUSPS == "NC")

# View the county boundaries for North Carolina
plot(nc_counties_sf)



# Ensure GEOID is character to match the data
firearmhomicide_data$GEOID <- as.character(firearmhomicide_data$GEOID)
nc_counties_sf$GEOID <- as.character(nc_counties_sf$GEOID)

# Merge the data with the North Carolina shapefile based on GEOID
merged_sf <- left_join(nc_counties_sf, firearmhomicide_data, by = "GEOID")



ggplot(merged_sf) +
  geom_sf(aes(fill = Rate), color = "white") +  # Color by Rate
  scale_fill_gradient(low = "palegreen", high = "palevioletred", name = "Rate") +  # I like pale green to red
  theme_minimal() +
  labs(title = "North Carolina", subtitle = "Rate of Firearm Homicide (2019-2023)") +
  theme(
    legend.position = "bottom",  # Bottom legend
    panel.grid = element_blank(),  # Remove gridlines
    axis.text.x = element_blank(),
    axis.text.y = element_blank()
  ) +
  facet_wrap(~ Year, ncol = 2)  # Create a separate map for each year




