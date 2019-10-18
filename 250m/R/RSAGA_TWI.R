rm(list = ls())

library(RSAGA)
library(rgdal)
library(raster)
library(tictoc)

#Working Directory
setwd("H:\\Region_1_RSAGA_TWI_HUC8_SDAT")

#Sets enviormental variables for SAGA
env <- rsaga.env(path = 'C:\\Users\\zachary.hoylman.UM\\Downloads\\saga-7.0.0_x64\\saga-7.0.0_x64',
                 modules = 'C:\\Users\\zachary.hoylman.UM\\Downloads\\saga-7.0.0_x64\\saga-7.0.0_x64\\tools',
                 parallel = TRUE, cmd = "saga_cmd.exe", cores = 8)

#Extracts files form working directory to work though
files = substr(list.files(pattern = "[[:digit:]].sdat", full.names = F),1,nchar(list.files(pattern = c("[[:digit:]].sdat"), full.names = F))-5)

#Find Files that have already been processed
files_already_processed = substr(list.files(pattern = "TWI.tif$", full.names = F),1,nchar(list.files(pattern = c("TWI.tif$"), full.names = F))-4)

#extract the reduced name to compare processed and un processed files
files_already_processed_short_name = substr(files_already_processed,1,nchar(files_already_processed)-4)

#find files that have not been processed
files_to_process = files[!(files %in% files_already_processed_short_name)]

#Reset Files
files = files_to_process

#Run files not already processed
for(f in 1:length(files)){
  tic("run time")
  #Convert tif to sgrd
  # rsaga.geoprocessor(lib="io_gdal", module=0, param=list(GRIDS=paste(getwd(),paste(files[f], ".sgrd", sep = ""),sep="/"), 
  #                                                        FILES=paste(getwd(),paste(files[f], ".tif", sep = ""),sep="/")), env = env)
  # 
  #Calculate TWI
  rsaga.geoprocessor(lib="terrain_analysis", module = "Topographic Wetness Index (One Step)", env = env,
                     param=list(DEM=paste(getwd(),paste(files[f], ".sgrd", sep = ""),sep="/"), 
                                TWI=paste(getwd(),paste(files[f],"_TWI.sgrd", sep = ""),sep="/"),
                                FLOW_METHOD = "Multiple Triangular Flow Direction"))
  #Export sgrd as tif
  rsaga.geoprocessor(lib="io_gdal", module=2, param=list(GRIDS=paste(getwd(),paste(files[f],"_TWI.sgrd", sep = ""),sep="/"), 
                                                         FILE=paste(getwd(),paste(files[f],"_TWI.tif", sep = ""),sep="/")), env = env)
  
  print(paste("------------",f, " out of ", length(files),"------------"), sep = "")
  toc()
}

example_crs = raster("H:\\Region_1_RSAGA_TWI_HUC8\\Watershed_DEM_HUC_07020001.tif")

#reproject
TWI_Rasters = substr(list.files(pattern = "TWI.tif", full.names = F),1,nchar(list.files(pattern = c("TWI.tif"), full.names = F))-4)

for(f in 1:length(TWI_Rasters)){
  tic()
  setwd("H:\\Region_1_RSAGA_TWI_HUC8_SDAT")
  temp_raster = raster(paste(TWI_Rasters[f],".tif", sep = ""))
  crs(temp_raster) = crs(example_crs)
  setwd("H:\\Region_1_RSAGA_TWI_HUC8_SDAT_Reproject")
  writeRaster(temp_raster, (paste(TWI_Rasters[f],".tif", sep = "")), format = "GTiff")
  toc()
  print(paste("------------",f, " out of ", length(TWI_Rasters),"------------"), sep = "")
}


#Mosaic Rasters
setwd("H:\\Region_1_RSAGA_TWI_HUC8_SDAT_Reproject")

rasterOptions(tmpdir='H:\\R_Temp')

name.list <- list.files(path=getwd(), 
                           pattern =".tif", full.names=TRUE)
raster.stack = list()

for(f in 1:length(name.list)){
  raster.stack[[f]] = raster(name.list[f])
  print(paste("------------",f, " out of ", length(TWI_Rasters),"------------"), sep = "")
}

#Define function for overlapping pixels
raster.stack$fun <- mean
tic()
#mosaic overall rasters in list
mos <- do.call(mosaic, raster.stack)
toc()

#Write out GTiff 
tic()
setwd("H:\\Region_1_Merged_Final")
writeRaster(mos, "Region_1_TWI_Mosaic.tif", format = "GTiff")
toc()

#Clip buffer cells around data
setwd("D:\\Western_US_TWI\\Full_DEM_Albers")
watershed_extent = readOGR("Region_1_HUC_8_Albers_472_Merged.shp")
mos_clipped = mask(mos, watershed_extent)

#Export Clipped Dataset
tic()
setwd("H:\\Region_1_Merged_Final")
writeRaster(mos_clipped, "Region_1_TWI_Mosaic_Clipped.tif", format = "GTiff")
toc()

#Import Def data to match TWI-DEF projections
def_data = raster("C:\\Users\\zachary.hoylman.UM\\Downloads\\DEF_apr-oct_1981-2015-30m_wgs_tps_predict.tif")

wgs84_crs = crs(def_data)

#Reproject TWI (Albers) to WGS84
tic()
mos_clipped_WGS84 = projectRaster(mos_clipped, crs = wgs84_crs ,method="bilinear")
toc()

#Export data in WGS84
tic()
setwd("H:\\Region_1_Merged_Final")
writeRaster(mos_clipped_WGS84, "Region_1_TWI_Mosaic_Clipped_WGS84.tif", format = "GTiff")
toc()


