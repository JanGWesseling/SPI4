module Types
  using Dates

  mutable struct Action
    readData :: Int64
    totalize :: Int64
    showMaps :: Int64
  end

  mutable struct MapSize
    nX :: Int64
    nY :: Int64
  end

  mutable struct CalculationPeriod
    firstDate :: DateTime
    lastDate :: DateTime
  end

  mutable struct Period
    name :: String
    length :: Int64
  end
  
end
