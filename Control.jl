module Control
  using ConfParser
  using Dates
  using Plots
  using Images
  using FileIO

  include("DataManager.jl")

  export process

  dirInput = ""
  dirHDF5 = ""
  dirMaps = ""

  action = Main.Types.Action(0,0,0)
  mapSize = Main.Types.MapSize(0,0)
  calculationPeriod = Main.Types.CalculationPeriod(Dates.today(), Dates.today())
  xCoord = Array{Float64}(undef,1)
  yCoord = Array{Float64}(undef,1)
  period = Array{Main.Types.Period}(undef,1)

  function readIniFile()
    result = 0
    fileName = "/media/wesseling/DataDisk/Wesseling/WesW/SPI4/Julia/SPI4.ini"
    df = DateFormat("dd-mm-yyyy")
    if isfile(fileName)
      iniFile = ConfParse(fileName)
      parse_conf!(iniFile)
      global dirInput = retrieve(iniFile, "Dir", "Input")
      global dirHDF5 = retrieve(iniFile, "Dir", "HDF5")
      global dirMaps = retrieve(iniFile, "Dir", "Maps")

      global action.readData = parse(Int64, retrieve(iniFile, "Action", "ReadData"))
      global action.totalize = parse(Int64, retrieve(iniFile, "Action", "Totalize"))
      global action.showMaps = parse(Int64, retrieve(iniFile, "Action", "ShowMaps"))

      global mapSize.nX = parse(Int64, retrieve(iniFile, "Maps", "HorSize"))
      global mapSize.nY = parse(Int64, retrieve(iniFile, "Maps", "VertSize"))

      resize!(xCoord, mapSize.nX)
      for i in 1:mapSize.nX
        xCoord[i] = i
      end

      resize!(yCoord, mapSize.nY)
      for i in 1:mapSize.nY
        yCoord[i] = i
      end

      n = parse(Int64, retrieve(iniFile, "Periods", "Number"))
      resize!(period,n)
      for i in 1:n
        period[i] = Main.Types.Period("",-1)
        name = "Period" * string(i)
#        println(name)
        global period[i].length = parse(Int64, retrieve(iniFile, "Periods", name))
        name = "Name" * string(i)
#        println(name)
        global period[i].name = retrieve(iniFile, "Periods", name)
      end

      global calculationPeriod.firstDate = DateTime(retrieve(iniFile, "CalculationPeriod", "FirstDate"), df)
      global calculationPeriod.lastDate = DateTime(retrieve(iniFile, "CalculationPeriod", "LastDate"), df)


      println("Ini exists")
    else
      println("???ERROR: Inifile does not exist!")
      result = -1
    end
    return result
  end

  function getFileNames(aDir :: String)
    fileName = Array{String}(undef,1)
    n = 0
    for (root, dirs, files) in walkdir(aDir, follow_symlinks=true)
      for myFile in files
        if endswith(myFile, ".h5")
          n += 1
          resize!(fileName,n)
          fileName[n] = joinpath(root,myFile)
        end
      end
    end
    return fileName
  end

  function totalizePrecipitation(aPeriod :: Int64, aDateTime :: DateTime) :: Int64
    status = 0
    pTot = Array{Float64}(undef,mapSize.nY,mapSize.nX)
    for i in 1:mapSize.nY
      for j in 1:mapSize.nX
        pTot[i,j] = 0.0
      end
    end

    try
      try
        myYear = Dates.year(aDateTime)
        myDay = Dates.dayofyear(aDateTime)
        fileName = "PrecSum" * string(aPeriod) * "y" * string(myYear) * ".h5"
        myFile = joinpath(dirHDF5, fileName)
  #      println(myFile)
        if !isfile(myFile)
          DataManager.createPrecSumFile(myFile, myYear, mapSize)
        end
        myDate = aDateTime - Dates.Day(aPeriod - 1)
        while myDate <= aDateTime
          p = DataManager.readPrecipitation(dirHDF5, Dates.year(myDate), Dates.dayofyear(myDate))
          pTot[:,:] += p[:,:]
          if p[300,300] > 100.0
            println(myDate, "   ",p[300,300],"  ",pTot[300,300])
          end
          myDate += Dates.Day(1)
        end
        status = DataManager.storePrecSums(myFile, myDay, pTot)
#        println(pTot[300,300])
  #       exit(0)

      catch e
        println("???Error in totalizePrecipitation: " * e)
        status = 1
      end
    finally
    end
    return status
  end

  function rgb(aRed::Int64, aGreen::Int64, aBlue::Int64)
    r = aRed / 255.0
    g = aGreen / 255.0
    b = aBlue / 255.0
    myColor = RGB(r,g,b)
    return myColor
  end

  function removeBorders(aFile :: String)
    p=load(File(format"PNG",aFile))
    q=p[15:720,50:675]
    save(aFile,q)
  end

  function showMaps(aPeriod :: Main.Types.Period, aDate :: DateTime)
    status = 0
    try
      try
#        println(size(xCoord,1))
#        println(size(yCoord,1))
        p = DataManager.readPrecSums(dirHDF5, aPeriod.length, Dates.year(aDate), Dates.dayofyear(aDate))

        valuesToPlot = Array{String}(undef, mapSize.nY, mapSize.nX)
        if aPeriod.length == 30
          global myColors = [rgb(220,220,220), rgb(255,0,0),  rgb(255,153,0),  rgb(255,204,0), rgb(255,255,0), rgb(204,255,0), rgb(0,204,0), rgb(0,102,0),  rgb(0,204,255), rgb(0,0,255), rgb(200,200,200) ]
          global values   = ["Onbekend",      "< 30",        "30 - 60",        "60 - 90",      "90 - 120",     "120 - 150",    "150 - 180",  "180 - 210",    "210 - 240",    "> 240",  "Onbekend"]
          global limit    = [1.0,            30.0,             60.0,            90.0,          120.0,           150.0,           180.0,      210.0,          240.0,          5000.0,   1.0e8]
        elseif aPeriod.length == 91
          global myColors = [rgb(220,220,220), rgb(255,0,0),  rgb(255,153,0),  rgb(255,204,0), rgb(255,255,5), rgb(204,255,0), rgb(0,204,0), rgb(0,102,0),  rgb(0,204,255), rgb(51,153,255), rgb(25,75,255),   rgb(0,0,255), rgb(200,200,200) ]
          global values   = ["Onbekend",      "< 100",        "100 - 150",     "150 - 200",    "200 - 250",     "250 - 300",    "300 - 350",  "350 - 400",    "400 - 450",    "450 - 500",      "500 - 550",    "> 550",       "Onbekend"]
          global limit    = [1.0,            100.0,            150.0,           200.0,          250.0,           300.0,           350.0,      400.0,          450.0,          500.0,             550.0,         5000.0,        1.0e8]
        elseif aPeriod.length == 182
          global myColors = [rgb(220,220,220), rgb(255,0,0), rgb(255,100,255), rgb(255,153,0),  rgb(255,204,0), rgb(228,118,36), rgb(187,93,25), rgb(255,255,25), rgb(245,252,158), rgb(204,255,0), rgb(180,221,131), rgb(0,204,0), rgb(0,150,0),  rgb(0,102,0),  rgb(115,229,240), rgb(0,204,255), rgb(51,153,255), rgb(25,75,255), rgb(0,0,255),  rgb(51,51,102), rgb(200,200,200) ]
          global values   = ["Onbekend",      "< 150",       "150 - 200",      "200 - 250",     "250 - 300",    "300 - 350",     "350 - 400",    "400 - 450",     "450 - 500",      "500 - 550",    "550 - 600",      "600 - 650",  "650 - 700",    "700 - 750",   "750 - 800",    "800 - 850",     "850 - 900",     "900 - 950",   "950 - 1000",    "> 1000",       "Onbekend"]
          global limit    = [10.0,            150.0,         200.0,            250.0,           300.0,          350.0,           400.0,           450.0,          500.0,            550.0,          600.0,             650.0,         700.0,         750.0,        800.0,            850.0,         900.0,           950.0,         1000.0,         5000.0,    1.0e8]
        elseif aPeriod.length == 365
          global myColors = [rgb(220,220,220), rgb(255,0,0), rgb(128, 0,0), rgb(255,100,255), rgb(255,153,0),  rgb(255,204,0), rgb(228,118,36), rgb(187,93,25), rgb(255,255,25), rgb(245,252,158), rgb(204,255,0), rgb(180,221,131), rgb(0,204,0), rgb(0,150,0),  rgb(0,102,0),  rgb(115,229,240), rgb(0,204,255), rgb(51,153,255), rgb(25,75,255), rgb(0,0,255),  rgb(51,51,102), rgb(200,200,200) ]
          global values   = ["Onbekend",      "< 450",      "450-500",      "500 - 550",      "550 - 600",     "600 - 650",    "650 - 700",     "700 - 750",    "750 - 800",     "800 - 850",      "850 - 900",    "900 - 950",      "950 - 1000", "1000 - 1050", "1050 - 1100", "1100 - 1150",    "1150 - 1200",  "1200 - 1250",   "1250 - 1300",  "1300 - 1350",  "> 1350", "Onbekend"]
          global limit    = [100.0,           450.0,         500.0,        550.0,            600.0,           650.0,          700.0,           750.0,           800.0,          850.0,            900.0,          950.0,            1000.0,        1050.0,        1100.0,       1150.0,           1200.0,         1250.0,          1300.0,         1350.0,         5000.0,    1.0e8]
        end

        for i in 1:mapSize.nY
          for j in 1:mapSize.nX
            k = 0
      #      println(p[i,])
            while k < size(limit,1)
              k += 1
              if p[i,j] < limit[k]
                valuesToPlot[i,j] = values[k]
                k = size(limit,1) + 1
#                println(valuesToPlot[i,j])
              end
            end
          end
        end

        df = DateFormat("dd/mm/yyyy")
        title = "Neerslagsom " * Dates.format(aDate, df) * ", " * aPeriod.name

#        m = heatmap(xCoord,yCoord,valuesToPlot)
        m = heatmap(xCoord,yCoord,valuesToPlot, xaxis=false, yaxis=false, legend = false, xlim=(230.0,520.0), ylim=(175.0,525.0), c=cgrad(myColors), size=(700,765))
        annotate!(240, 510, text(title, rgb(64,64,64), :left, 15))
        fileName = dirMaps * "PrecSum/" * aPeriod.name * "/PrecSum_" * aPeriod.name * "_" *  Dates.format(aDate,"yyyymmdd") * ".png"
        savefig(m, fileName)
        removeBorders(fileName)
      catch e
        status = 1
        println("???Error in showMaps: ", e)
      end
    finally
    end
    return status
  end


  function process()
    gr()

    status = 0
    status = readIniFile()
    if status != 0 # || dirInput == "None" || dirHDF5 == "None"
      println("???Error reading ini file. Processing stopped!")
    end
#    println(dirInput)
#    println(dirHDF5)
#    println(action)
#    println(mapSize)
#    println(period)
#    println(calculationPeriod)

    if status == 0 && action.readData == 1
      fileNames = getFileNames(dirInput)
      if size(fileNames,1) == 0
        println("WARNING: No files to read")
      else
        for i in 1:size(fileNames,1)
          if status == 0
            println("Processing file " * fileNames[i])
            status = DataManager.processKNMIFile(fileNames[i], dirHDF5)
          end
        end
      end
    end

    if status == 0 && action.totalize == 1
      for i in 4:size(period,1)
        myPeriod = period[i]
        println("Period = ", myPeriod.name)
        myDate = calculationPeriod.firstDate
        while myDate <= calculationPeriod.lastDate
          println(myDate)
          totalizePrecipitation(myPeriod.length, myDate)
          myDate += Dates.Day(1)
        end
      end
    end

    if status == 0 && action.showMaps == 1
      for i in 1:size(period,1)
        myPeriod = period[i]
        println("Period = ", myPeriod.name)
        myDate = calculationPeriod.firstDate
        while myDate <= calculationPeriod.lastDate
          println(myDate)
          status = showMaps(myPeriod, myDate)
          myDate += Dates.Day(1)
        end
      end
    end


    return status
  end

end
