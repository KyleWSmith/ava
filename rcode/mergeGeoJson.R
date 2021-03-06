# This R script combines all the GeoJSON files in a folder into one file, then writes it back to the folder.
# Modified from its original source: https://gist.github.com/wildintellect/582bb1096092170070996d21037b82d8

library(raster)
library(geojsonio)
library(rgdal)

# probably want to change the pattern to exclude or filter after to drop the all.geojson file
avas <- list.files(path="./avas", pattern = "*json$", full.names = "TRUE")
tbd <- list.files(path="./tbd", pattern = "*json$", full.names = "TRUE")

gj <- c(avas, tbd)

# exclude the all.geojson file... probably a more elegant way to do this, but this works:
gj <- gj[gj != "./avas.geojson"]
gj <- gj[gj != "./tbd/avas.geojson"]

#read all the geojson files
vects <- lapply(gj, geojson_read, what="sp")

#combine all the vectors together, bind is from the raster package
#probably could just rbind geojson lists too, but thats harder to plot
all <- do.call(bind, vects)

#Change any "N/A" data to nulls
all@data[all@data=="N/A"]<- NA

#Calculate area of polygons
#Example: x$area_sqkm <- area(x)
#all$area<-area(all)

#all@data$area <- sapply(slot(ploygons, "polygons"), function(i) slot(i, "area"))
all@data$area<-sapply(slot(all, "polygons"), function(i){slot(i, "area")})

#add the row names in a column
all$rows<-row.names(all)


#Order by area
#Example: meuse <- meuse[match(x[order(x$IDS),]$r, row.names(meuse@data)),]
#newdata <- mtcars[order(mpg, cyl),]

#all<-all[order(all$area),]

all<-all[match(all[order(all$area, decreasing = TRUE),]$rows, row.names(all@data)),]


#add new ID column
all$newid<-1:length(all)

#assign the new id to the ID field of each polygon

for (i in 1:nrow(all@data)){
  all@polygons[[i]]@ID<-as.character(all$newid[i])}

#drop unneccessary columns
all@data<-all@data[,1:(ncol(all@data)-3)]

geojson_write(all, file="avas.geojson", overwrite=TRUE, convert_wgs84 = TRUE)
