## Packages
library(ggplot2)
library(dplyr)

## Data needed
region_names = c("TAS", "EA", "SEA", "SWWA", "NA", "R")
text.type.large <- element_text(size = 12)
text.type.small <- element_text(size = 11)
data_dir = "/Users/saundersk1/Documents/Git/clusterExtremes/Data/"

# region_name = "SWWA" # region_names[r]
# grid_classify = readRDS(file = paste(data_dir, "classify_", region_name, ".rds", sep = ""))
# hclusters = readRDS(file = paste(data_dir, "cluster_", region_name, ".rds", sep = ""))
# 
# h_values = hclusters %>% select(h) %>% 
#   filter(h > 0.10 & h < 0.16) %>%
#   unlist() %>% as.numeric()

mainland_df = readRDS("/Users/saundersk1/Documents/Git/completionSeminar/shiny_apps/record_slider/mainland_df.rds")
tas_df = readRDS("/Users/saundersk1/Documents/Git/completionSeminar/shiny_apps/record_slider/tas_df.rds")

server <- function(input, output){
  
  output$recordPlot <- renderPlot({
    
    region_name = input$region
    grid_classify = readRDS(file = paste(data_dir, "classify_", region_name, ".rds", sep = ""))
    hclusters = readRDS(file = paste(data_dir, "cluster_", region_name, ".rds", sep = ""))
    
    h_values = hclusters %>% select(h) %>% 
      filter(h > 0.10 & h < 0.16) %>%
      unlist() %>% as.numeric()
    
    i = which.min(abs(h_values - as.numeric(input$cuth)))
    
    h_val = h_values[i]
    grid_input = grid_classify %>% filter(h == h_val)
    k_val = grid_input$k[1]
    
    grid_info = grid_input %>%
      mutate(z = class_id %>% as.numeric(), xc = x, yc=y) %>%
      select(-class_id)
    
    z = grid_info$z %>% as.numeric()
    x = grid_info$xc %>% as.numeric()
    y = grid_info$yc %>% as.numeric()
    
    grd <- data.frame(z = z, xc = x, yc = y)
    sp::coordinates(grd) <-~ xc + yc
    sp::gridded(grd) <- TRUE
    grd <- as(grd, "SpatialGridDataFrame")
    at <- 1:ceiling(max(z, na.rm = TRUE))
    plys <- inlmisc::Grid2Polygons(grd, level = FALSE, at = at)
    
    # get the classes from the map data
    map <- plys
    map@data$id = rownames(map@data)
    map.points = fortify(map) #, region="id")
    map.df = full_join(map.points, map@data, by="id")
    map.df = map.df %>%
      mutate(h = h_val, k = k_val)
    
    poly_df = map.df
    
    # title
    title_options = list("Tasmania" = "TAS", 
         "Southwest Australia" = "SWWA", 
         "Southeast Australia" = "SEA", 
         "Eastern Australia" = "EA", 
         "Northern Australia" = "NA", 
         "Regional Australia" = " R") %>% unlist()
    title_ind = which(title_options == input$region)
    plot_title = names(title_options)[title_ind]
    
    # get plot poly
    poly_plot_df <- poly_df %>%
      mutate(plot_group = paste(group, h)) %>%
      mutate(facet_title = paste("h = ", round(h, 4), " k = ", k))
    
    poly_plot <- ggplot() +
      geom_raster(data = grid_input,
                  aes(x=x, y=y, fill = as.factor(class_id), alpha = prob_summary)) +
      geom_polygon(data = poly_plot_df,
                   aes(long, lat, group = group),
                   color = "black", fill = NA) +
      coord_equal() +
      xlab("Longitude") +
      ylab("Latitude") +
      ggtitle(plot_title) +
      theme_bw() +
      theme(legend.position = "none",
            strip.text.x = text.type.large,
            axis.text = text.type.small,
            plot.title = text.type.large,
            axis.title = text.type.large)
  
    if(region_name == "TAS"){
      poly_plot <- poly_plot +
        geom_path(data = tas_df, aes(x = Long, y =Lat), col = "gray")
    }else{
      poly_plot <- poly_plot +
        geom_path(data = mainland_df, aes(x = Long, y =Lat), col = "gray") +
        scale_x_continuous(limits = range(x) + c(-0.25, 0.25)) +
        scale_y_continuous(limits = range(y) + c(-0.25, 0.25))
    }
    
    poly_plot
    
  })
  
}
