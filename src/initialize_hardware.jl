(@isdefined HANDLE) || (HANDLE = openUSBConnection(-1))
caliInfo = getCalibrationInformation(HANDLE)
(powerSupply == :Ultravolt) || (caliInfoTdac = getTdacCalibrationInformation(HANDLE, 2))

CPCType1, flowRate1, port1 = configure_serial_port(1)
CPCType2, flowRate2, port2 = configure_serial_port(2)
