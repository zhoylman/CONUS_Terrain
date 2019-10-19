library(doParallel)
library(foreach)
library(raster)
library(rgdal)
library(tictoc)
library(spdplyr)

#import full extent DEM
dem_raw = raster("/mnt/ScratchDrive/data/Hoylman/CONUS_Terrain_data/raster/dem_clipped_bicubic_CONUS_250m_mean_reducer.tif")
albers = raster("/mnt/ScratchDrive/data/Hoylman/ecosystem-sensitivity-data/rasters/250m_data/Ecosystem_Sensitivity_250m_mean_reducer_albers.tif")
watersheds_raw = readOGR("/mnt/ScratchDrive/data/Hoylman/CONUS_Terrain_data/shp/huc8_conus.shp")

#reproject to Albers
intended_crs = crs(albers)
dem = projectRaster(from = dem_raw, crs = intended_crs, res = 250, method="bilinear") 
writeRaster(dem,"/mnt/ScratchDrive/data/Hoylman/CONUS_Terrain_data/raster/dem_clipped_bicubic_CONUS_250m_mean_reducer_albers.tif")
watersheds = spTransform(watersheds_raw, intended_crs)
#Define Watershed HUC ids
ids = watersheds$HUC8

#fire up the cluster
cl = makeCluster(30)
registerDoParallel(cl)

#write dir def
write.dir = "/mnt/ScratchDrive/data/Hoylman/CONUS_Terrain_data/raster/huc8_dems"
length(ids)
#sum pet grids
foreach(i=1:length(ids)) %dopar% {  
  library(raster)
  rasterOptions(tmpdir='/mnt/ScratchDrive/data/Hoylman/raster_temp/')
  
  #Add Buffer around region 
  temp_mask_region = buffer(watersheds[watersheds$HUC8 == ids[i], ], width = 500)

  #Crop the extent
  temp_mask = crop(dem, extent(temp_mask_region))
  
  #mask out HUC id region
  temp_mask = mask(temp_mask, temp_mask_region)
  
  #Generate export file name
  temp_name = paste(write.dir, "/Watershed_DEM_HUC_",as.character(ids[i]),".sdat", sep = "")
  
  #write out data
  writeRaster(temp_mask,temp_name, format = "SAGA", datatype = 'INT2S', overwrite = T)
}

stopCluster(cl)
