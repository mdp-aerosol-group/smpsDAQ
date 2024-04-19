HANDLE = openUSBConnection(1)     # Internal Labjack connected to Ultravolt
HANDLE1 = openUSBConnection(3)    # External Labjack connected to blue rack
caliInfo = getCalibrationInformation(HANDLE)  
caliInfo1 = getCalibrationInformation(HANDLE1)
caliInfoTdac1 = getTdacCalibrationInformation(HANDLE1, 0) # TickDAC on outside

# Rack has 4 power supplies, two Ultravolt - LJ(1) and two Spellman - LJ(3)
powerSupply1 = :Ultravolt   
powerSupply2 = :Ultravolt 
powerSupply3 = :Spellman 
powerSupply4 = :Spellman 

CPCType1, flowRate1, port1 = configure_serial_port(1)
