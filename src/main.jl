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
using RegularizationTools

import NumericIO: UEXPONENT
(@isdefined wnd) && destroy(wnd)
config_file = "gui/UCRElectrometer.glade"
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
const slowLoop = fps(0.20)              # Slow loop for dew-point
const tenHz = fps(10.0 * 1.015272)      # 10 Hz time

const main_elapsed_time = foldp(+, 0.0, oneHz)
const smps_elapsed_time, smps_scan_state, smps_scan_number, termination, reset, V, Vs, Dp =
    smps_signals()

sleep(10)
const signalV = map(
    v -> [getVdac(v[1], :-, true), getVdac(v[2], :-, true), v[3] / 1000.0, v[4] / 1000.0],
    Vs,
)

sleep(3)

const labjack_signals1 = map(v -> labjackReadWrite(HANDLE, v[1], v[2], caliInfo; gain1 = 4), signalV)

sleep(3)

const labjack_signals2 = map(v -> labjackReadWrite(HANDLE1, v[3], v[4], caliInfo1; caliInfoTdac = caliInfoTdac1, gain1 = 0), signalV)

sleep(5)
const tenHzSMPSLoop = map(_ -> tenHz_smps_loop(), tenHz)   # 10 Hz SMPS

sleep(5)

const oneHzLoops = map(oneHz) do x
    push!(datestr, Dates.format(now(), "yyyymmdd"))
    @async oneHz_smps_loop()         # 1 Hz SMPS Loop
    @async oneHz_generic_loop()      # Generic 1 Hz DAQ (CPC, TE)
end

# const newDay = map(droprepeats(datestr)) do x
#     path3 = path * "Processed/"
#     read(`mkdir -p $path3`)
#     outfile = path3 * SizeDistribution_filename.value
#     @save outfile SizeDistribution_df δˢᵐᵖˢ Λˢᵐᵖˢ inversionParameters
#     try
#         deleterows!(SizeDistribution_df, collect(1:length(SizeDistribution_df[:Timestamp])))
#     catch
#     end
#     try
#         deleterows!(inversionParameters, collect(1:length(inversionParameters[:Timestamp])))
#     catch
#     end
#     push!(SizeDistribution_filename, Dates.format(now(), "yyyymmdd_HHMM") * ".jld2")
# end


# push!(smps_scan_state, "DONE")                # Termination signal to start new file

# signal_connect(selection, "changed") do widget
#     if hasselection(selection)
#         n = @_ map(listStore[_, 1], 1:length(listStore)) |> maximum
#         c = n - listStore[selected(selection), 1]
#         addseries!(
#             reverse(ninv[end].Dp),
#             reverse(ninv[end].S),
#             plot5,
#             gplot5,
#             1,
#             false,
#             true,
#         )
#         addseries!(
#             reverse(ninv[end-c].Dp),
#             reverse(ninv[end-c].S),
#             plot5,
#             gplot5,
#             2,
#             false,
#             true,
#         )
#         addseries!(
#             reverse(response[end].Dp),
#             reverse(response[end].N),
#             plot4,
#             gplot4,
#             2,
#             false,
#             true,
#         )
#         addseries!(
#             reverse(response[end-c].Dp),
#             reverse(response[end-c].N),
#             plot4,
#             gplot4,
#             3,
#             false,
#             true,
#         )
#     end
# end


# :DONE
