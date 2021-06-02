#+ 
# Functions that handle Labjack IO for YASP
#


# This function sets the send and receive buffers
function setupLabjackBuffers(Vdac0, Vdac1, BitFIO3, BitFIO4)
    # See pg. 83 of U6 Datasheet for protocol
    # Maintain C style zero indexing for bytes by using +1

    # Calibration and conditioning for Vdac0, Vdac1
    dacNumber = 0
    dBytesVolt =
        Vdac0 * caliInfo.ccConstants[17+dacNumber*2] + caliInfo.ccConstants[18+dacNumber*2]
    if dBytesVolt > 65535
        dBytesVolt = 65535
    elseif dBytesVolt < 0
        dBytesVolt = 0
    end
    binVoltage16 = convert(UInt16, round(dBytesVolt, digits = 0))
    LSB0 = UInt8(binVoltage16 & 255)
    MSB0 = UInt8((binVoltage16 & 65280) / 256)

    dacNumber = 1
    dBytesVolt =
        Vdac1 * caliInfo.ccConstants[17+dacNumber*2] + caliInfo.ccConstants[18+dacNumber*2]
    if dBytesVolt > 65535
        dBytesVolt = 65535
    elseif dBytesVolt < 0
        dBytesVolt = 0
    end
    binVoltage16 = convert(UInt16, round(dBytesVolt, digits = 0))
    LSB1 = UInt8(binVoltage16 & 255)
    MSB1 = UInt8((binVoltage16 & 65280) / 256)

    # 8 AIN 24bit, 1 AIN14 (T), 2 FIO Channels Dir + 2 FIO Write + 2 Counter + 2 DAC
    # IOType input bytes  = 8*4 + 1*4 + 2*2 + 2*2 + 2*2 + 2*3 = 54 bytes
    # IOType output bytes = 8*3 + 1*3 + 2*0 + 2*0 + 2*4 = 35 bytes

    # Send buffer in words = (1 + 54 + 1)/2 = 25
    # Receive buffer in words  = (8 + 35 + 1)/2 = 22
    sl, rl = (28 * 2 + 6), (22 * 2 + 8)   # Length of send buffer,receive buffer in bytes
    sendBuff, rec = zeros(UInt8, sl), zeros(UInt8, rl)

    # Block 1 Bytes 1-5 Configure Basic Setup
    # Bytes 0,4,5 are reserved for checksum
    sendBuff[1+1] = UInt8(0xF8)    # Command byte
    sendBuff[2+1] = 28             # Number of data words
    sendBuff[3+1] = UInt8(0x00)    # Extended command number

    # Block 2 Echo + Bytes 7-XX
    # Bytes 7-XX Configure Channels
    # Must be even number of bytes
    sendBuff[6+1] = 0           # Echo

    # AIN0
    sendBuff[7+1] = 2          # IOType is AIN24
    sendBuff[8+1] = 0          # Channel 0
    sendBuff[9+1] = 9 + 0 * 16   # Resolution & Gain
    sendBuff[10+1] = 0 + 0 * 128  # Settling & Differential 

    # AIN1
    sendBuff[11+1] = 2          # IOType is AIN24
    sendBuff[12+1] = 1          # Channel 1
    sendBuff[13+1] = 9 + 0 * 16   # Resolution & Gain
    sendBuff[14+1] = 0 + 0 * 128  # Settling & Differential

    # AIN2
    sendBuff[15+1] = 2          # IOType is AIN24
    sendBuff[16+1] = 2          # Channel 2
    sendBuff[17+1] = 9 + 0 * 16   # Resolution & Gain
    sendBuff[18+1] = 0 + 0 * 128  # Settling & Differential

    # AIN3
    sendBuff[19+1] = 2          # IO Type is AIN24
    sendBuff[20+1] = 3          # Channel 3
    sendBuff[21+1] = 9 + 0 * 16   # Resolution & Gain
    sendBuff[22+1] = 0 + 0 * 128  # Settling & Differential

    # AIN4
    sendBuff[23+1] = 2          # IO Type is AIN24
    sendBuff[24+1] = 4          # Channel 4
    sendBuff[25+1] = 9 + 0 * 16   # Resolution & Gain
    sendBuff[26+1] = 0 + 0 * 128  # Settling & Differential

    # AIN5
    sendBuff[27+1] = 2          # IO Type is AIN24
    sendBuff[28+1] = 5          # Channel 5
    sendBuff[29+1] = 9 + 0 * 16   # Resolution & Gain
    sendBuff[30+1] = 0 + 0 * 128  # Settling & Differential

    # AIN6
    sendBuff[31+1] = 2          # IO Type is AIN24
    sendBuff[32+1] = 6          # Channel 5
    sendBuff[33+1] = 9 + 0 * 16   # Resolution & Gain
    sendBuff[34+1] = 0 + 0 * 128  # Settling & Differential

    # AIN7
    sendBuff[35+1] = 2          # IO Type is AIN24
    sendBuff[36+1] = 7          # Channel 5
    sendBuff[37+1] = 9 + 0 * 16   # Resolution & Gain
    sendBuff[38+1] = 0 + 0 * 128  # Settling & Differential

    # AIN14
    sendBuff[39+1] = 2           # IOType is AIN24
    sendBuff[40+1] = 14          # Positive channel = 14 (temperature sensor)
    sendBuff[41+1] = 9 + 0 * 16    # Resolution & Gain 
    sendBuff[42+1] = 0 + 0 * 128   # SettlingFactor & Differential

    # FIO4
    sendBuff[43+1] = 13         # IOType is BitDirWrite
    sendBuff[44+1] = 4 + 1 * 128  # FIO3 & Direction = 1 (Output)

    # FIO5
    sendBuff[45+1] = 13         # IOType is BitDirWrite
    sendBuff[46+1] = 5 + 1 * 128  # FIO3 & Direction = 1 (Output)

    # FIO4
    sendBuff[47+1] = 11         # IOType is BitState Write
    sendBuff[48+1] = 4 + UInt8(BitFIO3) * 128  # FIO3 & Bit

    # FIO5
    sendBuff[49+1] = 11         # IOType is BitState Write
    sendBuff[50+1] = 5 + UInt8(BitFIO4) * 128  # FIO3 & Bit

    # Counter0
    sendBuff[51+1] = 54         # IOType is Counter0
    sendBuff[52+1] = 0          # Reset counter

    # Counter1
    sendBuff[53+1] = 55         # IOType is Counter1
    sendBuff[54+1] = 0          # Reset counter

    # DAC0, 16 bit
    sendBuff[55+1] = 38          # IOType is DAC# (16-bit)
    sendBuff[56+1] = LSB0        # Value LSB
    sendBuff[57+1] = MSB0        # Value MSB

    # DAC1, 16 bit
    sendBuff[58+1] = 39          # IOType is DAC# (16-bit)
    sendBuff[59+1] = LSB1        # Value LSB
    sendBuff[60+1] = MSB1        # Value MSB

    # Padding bye (size of a packet must be an even number of bytes)
    sendBuff[61+1] = 0

    # Create labjack buffer data types to pass to C-functions
    send = labjackBuffer{sl}(NTuple{sl,UInt8}(sendBuff[i] for i = 1:sl))
    rec = labjackBuffer{rl}(NTuple{rl,UInt8}(rec[i] for i = 1:rl))

    # Fills bytes 0,4,5 with checksums
    extendedChecksum!(send)
    return send, rec
end

function labjackReadWrite(Vdac0, Enable0)
    if (powerSupply == :Ultravolt)
        (Enable0 == true) || (Vdac0 = 0.0)
        sendIt, recordIt = setupLabjackBuffers(Vdac0, 0.0, true, false)
        setLJTDAC(HANDLE, caliInfoTdac, 2, 0.0, Vdac0)
	elseif (powerSupply == :TRek)
        (Enable0 == true) || (Vdac0 = 0.0)
        sendIt, recordIt = setupLabjackBuffers(0.0, 0.0, false, false)
		thepolarity = parse_box("ColumnPolaritySMPS")
		setLJTDAC(HANDLE, caliInfoTdac, 2, eval(thepolarity)(Vdac0), 5.0)
	else 
		sendIt, recordIt = setupLabjackBuffers(0.0, 0.0, false, false)
        (Enable0 == true) || (Vdac0 = 0.0)
        setLJTDAC(HANDLE, caliInfoTdac, 2, Vdac0, 5.0)
    end

    labjackSend(HANDLE, sendIt)
    labjackRead!(HANDLE, recordIt)
    AIN0 = calibrateAIN(caliInfo, recordIt, 9, 0, 1, 10, 11, 12)  # Calibrate AIN0
    AIN1 = calibrateAIN(caliInfo, recordIt, 9, 0, 1, 13, 14, 15)  # Calibrate AIN1
    AIN2 = calibrateAIN(caliInfo, recordIt, 9, 0, 1, 16, 17, 18)  # Calibrate AIN2
    AIN3 = calibrateAIN(caliInfo, recordIt, 9, 0, 1, 19, 20, 21)  # Calibrate AIN3
    AIN4 = calibrateAIN(caliInfo, recordIt, 9, 0, 1, 22, 23, 24)  # Calibrate AIN4
    AIN5 = calibrateAIN(caliInfo, recordIt, 9, 0, 1, 25, 26, 27)  # Calibrate AIN5
    AIN6 = calibrateAIN(caliInfo, recordIt, 9, 0, 1, 28, 29, 30)  # Calibrate AIN5
    AIN7 = calibrateAIN(caliInfo, recordIt, 9, 0, 1, 31, 32, 33)  # Calibrate AIN5
    AIN14 = calibrateAIN(caliInfo, recordIt, 9, 0, 1, 34, 35, 36)  # Calibrate AIN14
    Tk = caliInfo.ccConstants[23] * AIN14 + caliInfo.ccConstants[24] # Temp in K
    counts1 =
        recordIt.buff[37] +
        recordIt.buff[38] * 256 +
        recordIt.buff[39] * 65536 +
        recordIt.buff[40] * 16777216
    counts2 =
        recordIt.buff[41] +
        recordIt.buff[42] * 256 +
        recordIt.buff[43] * 65536 +
        recordIt.buff[44] * 16777216

    N1 = try
        (labjack_signals.value[3])[1]
    catch
        counts1
    end

    N2 = try
        (labjack_signals.value[3])[2]
    catch
        counts2
    end

    return [AIN0, AIN1, AIN2, AIN3, AIN4, AIN5, AIN6, AIN7],
    Tk,
    [counts1, counts2],
    [counts1 - N1, counts2 - N2]
end
