#Clear Data
rm(list = ls())

#library(doParallel)
#library(foreach)
library(raster)
library(rgdal)
library(tictoc)
library(spdplyr)

#import full extent DEM
setwd("D:\\Western_US_TWI\\Full_DEM_Albers")
dem = raster("Region_1_Full_DEM_Albers.tif")
watersheds = readOGR("Region_1_HUC_8_Albers.shp")

#setwd for dem export
setwd("H:\\Region_1_RSAGA_TWI_HUC8_SDAT")

#Define Watershed HUC ids
ids = watersheds$HUC8

#define temp folder location for temp data dump
rasterOptions(tmpdir='D:\\RStudio_Temp')

for(i in 1:length(ids)){
  tic("run time")
  rasterOptions(tmpdir='D:\\RStudio_Temp')
  
  #Add Buffer around region 
  temp_mask_region = buffer(watersheds[watersheds$HUC8 == ids[i], ], width = 100)

  #Crop the extent
  temp_mask = crop(dem, extent(temp_mask_region))
  
  #mask out HUC id region
  temp_mask = mask(temp_mask, temp_mask_region)
  
  #Generate export file name
  temp_name = paste("Watershed_DEM_HUC_",as.character(ids[i]),".sdat", sep = "")
  
  #write out data
  writeRaster(temp_mask,temp_name, format = "SAGA", datatype = 'INT2S')
  
  #Erase Temp Data
  do.call(file.remove, list(list.files("D:\\RStudio_Temp", full.names = TRUE)))
  
  #Print loop progress and timeing
  print(paste("------------" ,i, " out of ", length(ids),"------------"), sep = "")
  toc()
}

