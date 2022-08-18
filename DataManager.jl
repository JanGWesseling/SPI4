module DataManager
  using HDF5
  using Dates

  function createPrecipitationFile(aFile :: String, aYear :: Int64, aMapSize::Main.Types.MapSize) :: Int64
    status = 0
    println("Creating file " * aFile)
    fid = h5open(aFile, "cw")
    try
      try
        newData = Array{Float64}(undef,aMapSize.nY,aMapSize.nX)
        for j in 1:aMapSize.nY
          for i in 1:aMapSize.nX
            newData[j,i] = 0.0
          end
        end
    #        println(myData)
        daysInYear = 365
        if isleapyear(Date(aYear,1,1))
          daysInYear = 366
        end

        precGroup = g_create(fid, "Precipitation")
        attrs(precGroup)["Year"] = aYear
        attrs(precGroup)["Days"] = daysInYear
        attrs(precGroup)["nY"] = aMapSize.nY
        attrs(precGroup)["nX"] = aMapSize.nX
        attrs(precGroup)["NA"] = "999.0"
        attrs(precGroup)["Order"] = "y,x"

        for i in 1:daysInYear
          dayString = string(i)
          if i < 100
            dayString = "0" * dayString
            if i < 10
              dayString = "0" * dayString
            end
          end
#          println(dayString)

          dataSet = d_create(precGroup, dayString, datatype(Float64), dataspace(aMapSize.nY,aMapSize.nX))
          dataSet[:,:] = newData[:,:]
        end
      catch e
        println("???Error in createPrecipitationFile: " * e)
        status = 1
      end
    finally
      close(fid)
    end

    println(aFile * " created")
    return status
  end

  function createNameOfPrecFile(aDir :: String, aDateTime :: DateTime) :: String
    myYear = Dates.year(aDateTime)
    myName = aDir
    myName *= "Prec"
    myName *= string(myYear)
    myName *= ".h5"
    return myName
  end

  function processKNMIFile(aFile :: String, aOutputDir :: String) :: Int64
    status = 0
    if isfile(aFile)
      fid = h5open(aFile, "r")
      try
        try
          df = DateFormat("dd-u-yyyy;HH:MM:SS.sss")
#          println(names(fid))
          grGeographic = fid["geographic"]
          nmGeographic = names(grGeographic)
          grMapProjection = grGeographic[nmGeographic[1]]
          attribGeographic = h5readattr(aFile, "geographic")
#          println(attribGeographic)
          colOffset = attribGeographic["geo_column_offset"][1]
#          println(colOffset)
          rowOffset = attribGeographic["geo_row_offset"][1]
#          println(rowOffset)
          nCols = attribGeographic["geo_number_columns"][1]
#          println(nCols)
          nRows = attribGeographic["geo_number_rows"][1]
#          println(nRows)

          attribOverview = h5readattr(aFile, "overview")
#          println(attribOverview)
          startDate = DateTime(attribOverview["product_datetime_start"][1], df)
#          println(startDate)
          endDate = DateTime(attribOverview["product_datetime_end"][1], df)
#          println(endDate)

          dayNumber = Dates.dayofyear(endDate)
          dayString = string(dayNumber)
          if dayNumber < 100
            dayString = "0" * dayString
            if dayNumber < 10
              dayString = "0" * dayString
            end
          end

          nX = nCols
          nY = nRows

          mapSize = Main.Types.MapSize(nX, nY)

          filePrec = createNameOfPrecFile(aOutputDir, endDate)
#          println(filePrec)
          if !isfile(filePrec)
            status = createPrecipitationFile(filePrec, Dates.year(endDate), mapSize)
          end

          if status == 0
            fidOut = h5open(filePrec, "r+")

            myDataset = fid["image1/image_data"]
            myData = read(myDataset)
#            println(size(myData))
            newData = Array{Float64}(undef,nY,nX)
            for j in 1:nY
              k = nY - j + 1
              for i in 1:nX
                newData[k,i] = 0.01 * convert(Float64,myData[i,j])
                if newData[k,i] > 500.0
                  newData[k,i] = 999.0
                end
              end
            end
  #        println(myData)

            nameOutputDataset = "Precipitation/" * dayString
#            println(nameOutputDataset)
            datasetOutput = fidOut[nameOutputDataset]
            myData = read(datasetOutput)
#            println(myData[1,1])
            datasetOutput[:,:] += newData[:,:]

            println(endDate, "   ", newData[300,300], "   ", datasetOutput[300,300])

            close(fidOut)
          end
        catch e
          println("???Error in processKNMIFile: " * e)
          status = 1
        end
      finally
        close(fid)
  #      close(fid2)
      end
    else
      status = 1
      println("???File ", fileName, " does not exist!")
    end
    return status
  end

  function createPrecSumFile(aFile :: String, aYear :: Int64, aMapSize::Main.Types.MapSize) :: Int64
    status = 0
    println("Creating file " * aFile)
    fid = h5open(aFile, "cw")
    try
      try
        newData = Array{Float64}(undef,aMapSize.nY,aMapSize.nX)
        for j in 1:aMapSize.nY
          for i in 1:aMapSize.nX
            newData[j,i] = 0.0
          end
        end
    #        println(myData)
        daysInYear = 365
        if isleapyear(Date(aYear,1,1))
          daysInYear = 366
        end

        precGroup = g_create(fid, "PrecSum")
        attrs(precGroup)["Year"] = aYear
        attrs(precGroup)["Days"] = daysInYear
        attrs(precGroup)["nY"] = aMapSize.nY
        attrs(precGroup)["nX"] = aMapSize.nX
        attrs(precGroup)["NA"] = "999.0"
        attrs(precGroup)["Order"] = "y,x"

        for i in 1:daysInYear
          dayString = string(i)
          if i < 100
            dayString = "0" * dayString
            if i < 10
              dayString = "0" * dayString
            end
          end
#          println(dayString)

          dataSet = d_create(precGroup, dayString, datatype(Float64), dataspace(aMapSize.nY,aMapSize.nX))
          dataSet[:,:] = newData[:,:]
        end
      catch e
        println("???Error in createPrecSumFile: " * e)
        status = 1
      end
    finally
      close(fid)
    end

    println(aFile * " created")
    return status
  end

  function readPrecipitation(aDir :: String, aYear :: Int64, aDay :: Int64)
    p = Array{Float64}
    fileName = "Prec" * string(aYear) * ".h5"
    myFile = joinpath(aDir, fileName)
#    println(myFile)
    if isfile(myFile)
      fid = h5open(myFile, "r")
      try
        try
          dayString = string(aDay)
          if aDay < 100
            dayString = "0" * dayString
            if aDay < 10
              dayString = "0" * dayString
            end
          end
          myDatasetName = "Precipitation/" * dayString
#          println(myDatasetName)
          myDataset = fid[myDatasetName]
          p = read(myDataset)
          close(fid)
        catch e
          println("???Error in readPrecipitation: " * e)
          status = 1
        end
      finally
      end
    else
      status = 1
      println("???File ", myFile, " does not exist!")
    end
    return p
  end

  function storePrecSums(aFile :: String, aDay :: Int64, aArray :: Array{Float64})
    status = 0
    fid = h5open(aFile, "r+")
    try
      try
        dayString = string(aDay)
        if aDay < 100
          dayString = "0" * dayString
          if aDay < 10
            dayString = "0" * dayString
          end
        end
        myDatasetName = "PrecSum/" * dayString
        datasetOutput = fid[myDatasetName]
        myData = read(datasetOutput)
#            println(myData[1,1])
        datasetOutput[:,:] = aArray[:,:]
      catch e
        println("???Error in storePrecSums: " * e)
        status = 1
      end
    finally
      close(fid)
    end
    return status
  end

  function readPrecSums(aDir :: String, aPeriod :: Int64, aYear :: Int64, aDay :: Int64)
    status = 0
    p = Array{Float64}
    fileName = "PrecSum" * string(aPeriod) * "y" * string(aYear) * ".h5"
    myFile = joinpath(aDir, fileName)
#    println(myFile)
    if isfile(myFile)
      fid = h5open(myFile, "r")
      try
        try
          dayString = string(aDay)
          if aDay < 100
            dayString = "0" * dayString
            if aDay < 10
              dayString = "0" * dayString
            end
          end
          myDatasetName = "PrecSum/" * dayString
#          println(myDatasetName)
          myDataset = fid[myDatasetName]
          p = read(myDataset)
          close(fid)
        catch e
          println("???Error in readPrecSums: " * e)
          status = 1
        end
      finally
      end
    else
      status = 1
      println("???File ", myFile, " does not exist!")
    end
    return p
  end

end
