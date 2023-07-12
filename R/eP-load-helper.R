######## eP.load.helper() ###########
#' Manages data loading of evalPurency
#' @description
#' Shared by both main function of the evalPurency package. Loads data from all *.csv files from the 
#' provided folter.
#' 
#' @param path The path set by the user in main function.
#' @param sep Column separator within the *.csv files. Defaults to ';' in main function.
#' @param dec Decimal sign within the *.csv files. Defaults to ',' in main function.
#' @param colL Column number for the particle length. In the TOEKI lab this is column 17 (Length 5µ). 
#' Could also be provided as column name, but only in ASCII encoding (e.g., special character as . and ä = d).
#' Set in main function.
#' @param colPol Column number where the polymer type is stated. In the TOEKI lab this is column 6 (Class Name). 
#' The polymer names (or abbreviations) can be set manually in 'polymers' in case the default does not apply.
#' Could also be provided as column name, but only in ASCII encoding (e.g., special character as . and ä = d).
#' Set in main function.
#' @param startrow Number of rows that can be omitted from the *.csv files. There Purency 
#' provides a bunch of meta data, that are not of interest here. Defaults to 40 in main function.
#' @param colReqPol Column number for the particle check, whether the particle is a polymer or not. 
#' In the TOEKI lab this is column 24 (Plastik? or Plastik ja/nein). Could also be provided as column name, but only 
#' in ASCII encoding (e.g., special character as . and ä = d). Set in main function.
#' @param ReqPolKey key word or sentence of 'colReqPol' that indicates that it is a plastic particle. 
#' Default is 'ja'. Set in main function.
#' @param colShape Column number for the particle shape. In the TOEKI lab this is column 25 (Form).
#' Could also be provided as column name, but only in ASCII encoding (e.g., special character as . and ä = d).
#' Set in main function.
#' @param colCol Column number for the particle color In the TOEKI lab this is column 26 (Farbe).
#' Could also be provided as column name, but only in ASCII encoding (e.g., special character as . and ä = d).
#' Set in main function.
#' @param colLFib Column number for the particle length in case of a fibre with corrected length (because of curvy shape)
#' In the TOEKI lab this is column 27 (Länge). Could also be provided as column name, but only in ASCII encoding (e.g., special character as . and ä = d).
#' Set in main function.
#' @param colArea Column number for the particle length in case of a fibre with corrected length (because of curvy shape)
#' In the TOEKI lab this is column 4 (Area µm²). Could also be provided as column name, but only in ASCII encoding (e.g., special character as . and ä = d).
#' Set in main function.
#' @param colWidth Column number for the particle length in case of a fibre with corrected length (because of curvy shape)
#' In the TOEKI lab this is column 18 (Width µm). Could also be provided as column name, but only in ASCII encoding (e.g., special character as . and ä = d).
#' Set in main function.
#' @param test Can be set TRUE when the function should be run in testing mode. Set in main function.
#' @param fibre How fibres are called in colShape (Form). In the TOEKI lab it is 'Faser'.
#' @param sphere How spheres are called in colShape (Form). In the TOEKI lab it is 'Kugel'.
#' @param fragment How fragments are called in colShape (Form). In the TOEKI lab it is 'Fragment'.
#' @param pixel How pixels are called in colShape (Form). In the TOEKI lab it is 'Pixel'.
#' 
#' @return Returns a data frame containing a list of all particles and their properties.


ep.load.helper <- function(path, 
                           sep, 
                           dec, 
                           colL,
                           colPol,
                           startrow, 
                           colReqPol, 
                           ReqPolKey, 
                           colShape, 
                           colCol, 
                           colLFib,
                           colArea,
                           colWidth,
                           test,
                           fibre,
                           sphere,
                           fragment,
                           pixel
                           ){
  if(test == FALSE){
    #### load files ####
    # get all files in the set folder
    Dateien <- list.files(path=path,pattern=".csv") # search for files with .csv ending
    # get the number of files
    name_measurement <- c(1:length(Dateien))
    
    # prepare files names to be used in read.csv()
    # and get the sample names (all before the fist _)
    for (i in 1:length(Dateien)){  
      names(Dateien)[i] <-Dateien[i] # generate names for values
      names(Dateien)[i] <-strsplit(names(Dateien)[i],".csv")[[1]][1]  # cut of '.txt' of the name
      name_measurement[i] <- strsplit(names(Dateien)[i],"_")[[1]][1]  # cut of '.txt' of the name
    }
    
    # temp data frame to store content of all files
    temp <- data.frame()
    
    # read all files and gather their data in temp
    # each particle will be stored in one line with the measurement number and sample name (unique combination).
    suppressWarnings(
      for (i in 1:length(Dateien)){
        
        # need to read data as ASCII. Otherwise it sometimes makes problems with the column names with special character
        assign("Hilfsobjekt",read.csv(paste0(path,Dateien[i]),sep=sep, dec=dec, skip=startrow, fileEncoding = "latin1")) # read data and skip the first 40 lines
        
        # now with column numbers in the default form, but can also be provided als column name
        Hilfsobjekt <- droplevels(subset(Hilfsobjekt, Hilfsobjekt[colReqPol] == ReqPolKey))
        
        
        
        
        temp2 <- data.frame(sample = name_measurement[i],
                            measurement = Dateien[i],
                            className = Hilfsobjekt[, colPol], # polymer type
                            length = Hilfsobjekt[, colL], # length of the particle
                            form = Hilfsobjekt[, colShape], # fragment, pixel, fibre, sphere
                            lengthFibre = Hilfsobjekt[, colLFib], # in case the fibre is curved, the length can be found here
                            color = Hilfsobjekt[, colCol], # color, Area and width are just for completeness of raw data. Not important for any calculation
                            area = Hilfsobjekt[, colArea],
                            width = Hilfsobjekt[, colWidth]) 
        temp <- rbind(temp, temp2)
      }
    ) # end supressWarnings
    # until here the sample data are produced. This is what Purency provides
  } # end if test == FALSE
  else{ # if test == TRUE
    # load data from package sample data
    temp <- evalPurency::purencySampleData
  }  
  
  # quality control
  rowstodelete <- c()
  for(i in 1:nrow(temp)){
    check <- FALSE
    suppressWarnings( # I supress the warnings to have a simpler message that can be interpreted fast.
      # To add a quality control, I check whether the field of form or length is NA. If yes, a warning will be
      # thrown, including the sample and measurement.
      if(is.na(temp$form[i]) == TRUE || (temp$form[i] == fibre || temp$form[i] == fragment || temp$form[i] == pixel || temp$form[i] == sphere) == FALSE){
        check <- TRUE
        if(is.na(temp$form[i]) == TRUE){
          cat(warning(paste("Warning: There is a value missing in column ", colnames(Hilfsobjekt[colShape]), " in ", temp$measurement[i], "\n")))
        }
        else{
          cat(warning(paste("Warning: There is an unknown value in column ", colnames(Hilfsobjekt[colShape]), " in ", temp$measurement[i], "\n")))
        }
      }
    ) # end supressWarnings
    suppressWarnings(
      if(is.na(as.numeric(temp$length[i])) == TRUE){
        check <- TRUE
        cat(warning(paste("Warning: There is a value missing in column ", colnames(Hilfsobjekt[colL]), " in ", temp$measurement[i], "\n")))
      }
    ) # end supressWarnings
    if(check == TRUE){
      rowstodelete <- c(rowstodelete, i)
    }
  } # end for(i)
  if(length(rowstodelete) > 0){
    temp <- temp[-c(rowstodelete),]
  }
  
  # The length is not always correct for fibres.
  # Thus create a new column with the correct length for all particles (that I don't need to select the correct column further below)
  temp$actualLength <- NA
  for(i in 1:nrow(temp)){
    # If lengthFibre is NA, but form is still Faser, the length is the value to be taken.
    if(temp$form[i] == fibre && !is.na(temp$lengthFibre[i]) == TRUE){
      temp$actualLength[i] <- temp$lengthFibre[i]
    }
    else{
      temp$actualLength[i] <- temp$length[i]
    }
  } # end for i
  
  return(temp)  

}