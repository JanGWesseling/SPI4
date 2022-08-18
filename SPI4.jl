################################################################################
#                                                                              #
# Program to compute Standardized Precipitation Index. This is the fourth      #
# version of the project (SPI4)                                                #
#                                                                              #
# Author: Jan G. Wesseling                                                     #
#         Wageningen University and Research, Soil Physics and Land Management #
#         Wageningen Environmental Software                                    #
#                                                                              #
# Version: 0.1                                                                 #
# Date: 13 April 2020                                                          #
#                                                                              #
################################################################################
  using Dates
  include("Types.jl")
  include("Control.jl")

  df = DateFormat("dd-u-yyyy HH:MM:SS.sss")
  println("Program started at " * Dates.format(Dates.now(), df))

  Control.process()

  println("Program ended at " * Dates.format(Dates.now(), df))
