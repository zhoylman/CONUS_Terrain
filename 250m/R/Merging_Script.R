rm(list = ls())

library(RSAGA)
library(raster)
library(tictoc)
library(pracma)

#Working Directory
setwd("H:\\Region_1_RSAGA_TWI_HUC8_Merge")

#Sets enviormental variables for SAGA
env <- rsaga.env(path = 'C:\\Users\\zachary.hoylman.UM\\Downloads\\saga-7.0.0_x64\\saga-7.0.0_x64',
                 modules = 'C:\\Users\\zachary.hoylman.UM\\Downloads\\saga-7.0.0_x64\\saga-7.0.0_x64\\tools',
                 parallel = TRUE, cmd = "saga_cmd.exe", cores = 8)

#Extracts files form working directory to work though
dem_files = substr(list.files(pattern = "[[:digit:]].tif", full.names = F),1,nchar(list.files(pattern = c("[[:digit:]].tif"), full.names = F))-4)

#Find Files that have already been processed
twi_files = substr(list.files(pattern = "TWI.tif", full.names = F),1,nchar(list.files(pattern = c("TWI.tif"), full.names = F))-4)

#extract the reduced name to compare processed and un processed files
twi_files_short = substr(twi_files,1,nchar(twi_files)-4)

#Check to see if extents are the same
for(i in 1:10){
  tic("runtime")
  rasterOptions(tmpdir='D:\\R_Temp')
  setwd("H:\\Region_1_RSAGA_TWI_HUC8_Merge")
  temp_dem = raster(paste(dem_files[i], ".tif", sep = ""))
  temp_twi = raster(paste(twi_files[i], ".tif", sep = ""))
  
  print(all.equal(extent(temp_dem), extent(temp_twi)))
  
  extent(temp_twi) = extent(temp_dem)
  
  setwd("H:\\Modified_Extent")
  writeRaster(temp_twi,paste(twi_files[i], "_mod", ".tif", sep = ""),datatype = 'FLT4S', overwrite = T)
  toc()
  print(paste("-------------",i, "out of", 10,"-------------"))
}
