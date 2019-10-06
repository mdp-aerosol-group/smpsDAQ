# -
# cpc_serial.io
#
# Configuration and read routines for seria communication with 
# condensation particle counters. Currently supported models
# TSI 3022 (Precursor of the ultrafine CPC)
# TSI 3762 (a low cost version of TSI 3010)
# TSI 3771/3772 (follow model of TSI 3010)
# TSI 3776C (nano particle counter)
#
# Functions: 
#  (1) configure_serial_port - Read config from GUI and setup port
#  (2) read_cpc - query CPC and return concentration
#
#

# Author: Markus Petters
#         NC State University
#         Raleigh, NC 27695-8208
# -

# This function polls the gui for port information.
# Opens and configures port
function configure_serial_port(n)
	CPC = get_gtk_property(gui["CPCType$n"], "active-id", String)
	q = get_gtk_property(gui["CPCSampleFlow$n"], "text", String)
	baud = get_gtk_property(gui["BaudRate$n"], "active-id", String)
	dbits = get_gtk_property(gui["DataBits$n"], "active-id", String)
	p = get_gtk_property(gui["Parity$n"], "active-id", String)
	sbits = get_gtk_property(gui["StopBits$n"], "active-id", String)

	flowRate = parse(Float64,q)
	CPCType = Symbol(CPC)
	
	serialPort = get_gtk_property(gui["SerialPort$n"], "text", String)
	baudRate = parse(Int,baud)
	dataBits = parse(Int,dbits)
	stopBits = parse(Int,sbits)
	parity = eval(Symbol(p))

	port = sp_get_port_by_name(serialPort)
	sp_open(port, SP_MODE_READ_WRITE)
	config = sp_get_config(port)
	sp_set_config_baudrate(config, baudRate)
	sp_set_config_parity(config, parity)
	sp_set_config_bits(config, dataBits)
	sp_set_config_stopbits(config, stopBits)
	sp_set_config_rts(config, SP_RTS_OFF)
	sp_set_config_cts(config, SP_CTS_IGNORE)
	sp_set_config_dtr(config, SP_DTR_OFF)
	sp_set_config_dsr(config, SP_DSR_IGNORE)

	sp_set_config(port, config)

	return CPCType, flowRate, port
end

# Query CPC and return concentration
# Note that flowrate is only iunvoced for 3762
function readCPC(port, CPCType, flowRate)
	sp_drain(port)
	sp_flush(port, SP_BUF_OUTPUT)

	if CPCType == :TSI3022 
		sp_nonblocking_write(port, "RD\r")
		nbytes_read, bytes = sp_nonblocking_read(port,  10)
		c = String(bytes)
		f = split(c,"\r")
		N = try 
			parse(Float64,f[1])
		catch 
			missing
		end
	end

	if CPCType == :TSI3762 
		sp_nonblocking_write(port, "RB\r")
		nbytes_read, bytes = sp_nonblocking_read(port,  10)
		c = String(bytes)
		f = split(c,"\r")
		N = try 
			parse(Float64,f[1])/60.0
		catch 
			missing
		end
		N = N*3.0/flowRate
	end

	if (CPCType == :TSI3771) || (CPCType == :TSI3772) || (CPCType == :TSI3776C) 
		sp_nonblocking_write(port, "RALL\r")
		nbytes_read, bytes = sp_nonblocking_read(port,  100)
		c = String(bytes)
		f = split(c,",")
		N = try 
			parse(Float64, f[1])
		catch
			missing
		end
	end

	N
end
