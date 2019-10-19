libs <- c("rgdal", "maptools", "gridExtra", "dplyr", "sf", "rgdal")
lapply(libs, require, character.only = TRUE)

huc8 = sf::st_read(dsn = "/mnt/ScratchDrive/data/Hoylman/conus_TWI_data/shp/huc8_conus.shp")

states = sf::st_read("/mnt/ScratchDrive/data/Hoylman/conus_TWI_data/shp/states.shp")

states = st_transform(states, "+init=epsg:4326")

states_west = states %>%
  dplyr::filter(STATE_ABBR %in% c("WA", "OR", "MT", "ID",
                                  "WY", "CA", "NV", "UT", 
                                  "CO", "AZ", "NM"))

huc8_west = st_intersection(states_west, huc8)

huc8_union = huc8_west %>%
  st_union() %>%
  st_sf()

sf::st_write(huc8_union, "/mnt/ScratchDrive/data/Hoylman/conus_TWI_data/shp/huc8_west_union.shp")
