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
using Lazy
using NumericIO
using Underscores
using DataStructures

import NumericIO: UEXPONENT

(@isdefined wnd) && destroy(wnd)
gui = GtkBuilder(filename = pwd() * "/" * config_file)  # Load GUI
wnd = gui["mainWindow"]

include("helper_functions.jl")        # Various helpers related to GTK
include("global_constants.jl")        # Reactive Signals global constants
include("cpc_serial_io.jl")           # CPC I/O
include("hygroclip_io.jl")            # Hygroclip HC2 functions
include("hv_io.jl")                   # High voltage power supply
include("initialize_hardware.jl")     # Assign ports, get Labjack HANDLE
include("labjack_io.jl")              # Labjack channels I/O
include("set_gui_initial_state.jl")   # Initialize graphs 
include("smps_signals.jl")            # SMPS Logic and Signals
include("daq_loops.jl")               # Contains DAQ loops               

Gtk.showall(wnd)                      # Show GUI

# Generate signals
const oneHz = fps(1.0 * 1.0015272)      # 1  Hz time
const slowLoop = fps(0.20)               # Slow loop for dew-point
const tenHz = fps(10.0 * 1.015272)      # 10 Hz time

const main_elapsed_time = foldp(+, 0.0, oneHz)
const smps_elapsed_time, smps_scan_state, smps_scan_number, termination, reset, V, Dp =
    smps_signals()
const signalV = map(calibrateVoltage, V)  # Convert logic voltage to signal voltage
const labjack_signals = map((v0, p0) -> labjackReadWrite(v0, p0), signalV, powerSMPS)

# Instantiate parallel 1 Hz Loops and start 10 Hz loop
const oneHzLoops = map(oneHz) do x
    push!(datestr, Dates.format(now(), "yyyymmdd"))

    @async oneHz_smps_loop()         # 1 Hz SMPS Loop
    @async oneHz_generic_loop()      # Generic 1 Hz DAQ (CPC, TE)
    @async oneHz_data_file()         # Write data file
end

const newDay = map(droprepeats(datestr)) do x
    path3 = path * "Processed/"
    read(`mkdir -p $path3`)
    outfile = path3 * SizeDistribution_filename.value
    @save outfile SizeDistribution_df δˢᵐᵖˢ Λˢᵐᵖˢ inversionParameters
    try
        deleterows!(SizeDistribution_df, collect(1:length(SizeDistribution_df[:Timestamp])))
    catch
    end
    try
        deleterows!(inversionParameters, collect(1:length(inversionParameters[:Timestamp])))
    catch
    end
    push!(SizeDistribution_filename, Dates.format(now(), "yyyymmdd_HHMM") * ".jld2")
end

const tenHzSMPSLoop = map(_ -> tenHz_smps_loop(), tenHz)   # 10 Hz SMPS

push!(smps_scan_state, "DONE")                # Termination signal to start new file

signal_connect(selection, "changed") do widget
    if hasselection(selection)
        n = @_ map(listStore[_,1], 1:length(listStore)) |> maximum
        c = n - listStore[selected(selection),1] 
        addseries!(reverse(ninv[end].Dp), reverse(ninv[end].S), plot5, gplot5, 1, false, true)
        addseries!(reverse(ninv[end-c].Dp), reverse(ninv[end-c].S), plot5, gplot5, 2, false, true)
        addseries!(reverse(response[end-c].Dp), reverse(response[end-c].N), plot4, gplot4, 2, false, true)
    end
end


:DONE
