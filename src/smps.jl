using Gtk
using InspectDR
using Reactive
using Colors
using DataFrames    
using Printf
using Dates
using CSV
using JLD2
using FileIO
using LibSerialPort
using Interpolations
using LinearAlgebra
using Statistics  
using LambertW
using LabjackU6Library
using DifferentialMobilityAnalyzers

(@isdefined wnd) && destroy(wnd)
gui = GtkBuilder(filename=pwd()*"/"*config_file)  # Load GUI
wnd = gui["mainWindow"]

include("global_variables.jl")        # Reactive Signals and global variables
include("gtk_callbacks.jl")           # Link GUI content with code 
include("cpc_serial_io.jl")           # CPC I/O
include("hygroclip_io.jl")            # Hygroclip HC2 functions
include("hv_io.jl")                   # High voltage power supply
include("initialize_hardware.jl")     # Assign ports, get Labjack HANDLE
include("labjack_io.jl")              # Labjack channels I/O
include("gtk_graphs.jl")              # push graphs to the UI#
include("set_gui_initial_state.jl")   # Initialize graphs 
include("smps_signals.jl")            # SMPS Logic and Signals
include("daq_loops.jl")               # Contains DAQ loops               

Gtk.showall(wnd)                      # Show GUI

# Generate signals
const oneHz = fpswhen(switch,1.0*1.0015272)         # 1  Hz time
const slowLoop = fpswhen(switch,0.20)               # Slow loop for dew-point
const tenHz = fpswhen(switch,10.0*1.015272)         # 10 Hz time
const main_elapsed_time = foldp(+, 0.0, oneHz)      # Main timer
const smps_elapsed_time,smps_scan_state,smps_scan_number,termination,reset,V,Dp = smps_signals()
const signalV  = map(calibrateVoltage, V)           # Convert logic voltage to signal voltage
const labjack_signals = map((v0,p0)->labjackReadWrite(v0,p0),signalV,powerSMPS)

# Instantiate parallel 1 Hz Loops and start 10 Hz loop
const oneHzLoops = map(oneHz) do x
    (useSMPS.value == false) && push!(useSMPS, true) # Start 10 Hz SMPS loop

    push!(datestr,Dates.format(now(), "yyyymmdd"))

    @async oneHz_smps_loop()         # 1 Hz SMPS Loop
    @async oneHz_generic_loop()      # Generic 1 Hz DAQ (CPC, TE)
    @async oneHz_data_file()         # Write data file
end

const newDay = map(droprepeats(datestr)) do x
    path3 = path*"Processed/"
    outfile = path3*"/"*SizeDistribution_filename
    @save outfile SizeDistribution_df δˢᵐᵖˢ Λˢᵐᵖˢ inversionParameters
    try; deleterows!(SizeDistribution_df,collect(1:length(SizeDistribution_df[:Timestamp]))); catch; end;          
    try; deleterows!(inversionParameters,collect(1:length(inversionParameters[:Timestamp]))); catch; end;             
    global SizeDistribution_filename = Dates.format(now(), "yyyymmdd_HHMM")*".jld2"
end

const tenHzSMPSLoop = map(_ -> tenHz_smps_loop(), tenHz)   # 10 Hz SMPS

push!(smps_scan_state, "DONE")                # Termination signal to start new file
push!(useSMPS, false)                                # Turn off SMPS loop
push!(switch, false)                                 # Turn off SMPS loop


:DONE	
