const Godot = @task _ -> false
const _Gtk = Gtk.ShortNames
const black = RGBA(0, 0, 0, 1)
const red = RGBA(0.8, 0.2, 0, 1)
const mblue = RGBA(0, 0, 0.8, 1)
const mgrey = RGBA(0.4, 0.4, 0.4, 1)
const lpm = 1.666666e-5
const lowerDchart = parse_box("LowerDchart", 5.0)
const upperDchart = parse_box("UpperDchart", 5.0)
const bufferlength = 400
const eCharge = 1.602176634e−19

const t = parse_box("TemperatureSMPS", 22.0) + 273.15
const p = parse_box("PressureSMPS", 1001.0) * 100.0
const qsh = parse_box("SheathFlowSMPS", 10.0) * lpm
const qsa = parse_box("SampleFlowSMPS", 1.0) * lpm
const leff = parse_box("EffectiveLength", 0.0)
const bins = parse_box("NumberOfBins", 120)
const τᶜ = parse_box("PlumbTime", 4.1)
const polarity = :-
const powerSupply = :Spellman
const column = :HFDMA
const Λˢᵐᵖˢ, δˢᵐᵖˢ = set_SMPS_config()
const path = mapreduce(a -> "/" * a, *, (pwd()|>x->split(x, "/"))[2:3]) * "/Data/"

const outfile = path * Dates.format(now(), "yyyymmdd_HHMM") * ".csv"
const powerSMPS = Reactive.Signal(true)
const datestr = Reactive.Signal(Dates.format(now(), "yyyymmdd"))

const tenHz_df = DataFrame(
    Timestamp = DateTime[],
    Unixtime = Float64[],
    Int64time = Int64[],
    LapseTime = String[],
    state = Symbol[],
    voltageSet1 = Float64[],
    voltageRead1 = Float64[],
    voltageSet2 = Float64[],
    voltageRead2 = Float64[],
    voltageSet3 = Float64[],
    voltageRead3 = Float64[],
    voltageSet4 = Float64[],
    voltageRead4 = Float64[],
    setDiameter = Float64[],
    scanDiameter = Float64[],
    N1cpcCount = Float64[],
    N1cpcSerial = Union{Float64,Missing}[],
    electrometerV = Float64[],
    electrometerN = Float64[],
    RHsh = Union{Float64,Missing}[],
    Tsh = Union{Float64,Missing}[],
    Tdsh = Union{Float64,Missing}[],
    RHsa = Union{Float64,Missing}[],
    Tsa = Union{Float64,Missing}[],
    Tdsa = Union{Float64,Missing}[],
)

const inversionParameters = DataFrame(
    Timestamp = String[],
    Ncpc = Union{Float64,Missing}[],
    N = Float64[],
    A = Float64[],
    V = Float64[],
    useCounts = Bool[],
)

const ℝ = @as x begin
    zeros(length(δˢᵐᵖˢ.Dp))
    SizeDistribution([[]], δˢᵐᵖˢ.De, δˢᵐᵖˢ.Dp, δˢᵐᵖˢ.ΔlnD, x, x, :response)
    Signal(x)
end

const SizeDistribution_df = DataFrame(
    Timestamp = DateTime[],
    useCounts = Bool[],
    Response = SizeDistribution[],
    Inverted = SizeDistribution[],
    oneHz_df = DataFrame[],
    tenHz_df = DataFrame[],
)

const SizeDistribution_filename = Signal(Dates.format(now(), "yyyymmdd_HHMM") * ".jld2")

const ninv = CircularBuffer{SizeDistribution}(100)
const response = CircularBuffer{SizeDistribution}(100)

# GTK Stuff
#
# terminate the script
const mainWindow = gui["mainWindow"]
const id1 = signal_connect(mainWindow, "destroy") do widget, others...
    schedule(Godot)
end

const sbox = gui["ClassifierDiameter"]
const classifierD = Signal(get_gtk_property(sbox, "value", Float64))
const id2 = signal_connect(sbox, "value-changed") do widget, others...
    set_voltage_SPINBox(sbox, "ClassifierV")
    cD = get_gtk_property(sbox, "value", Float64)
    push!(classifierD, cD)
end

const sboxBaseline = gui["Baseline"]
const vBaseline = Signal(get_gtk_property(sboxBaseline, "value", Float64))
const id10 = signal_connect(sboxBaseline, "value-changed") do widget, others...
     vB = get_gtk_property(sboxBaseline, "value", Float64)
     push!(vBaseline, vB)
end

const sboxElectrometerFlow = gui["ElectrometerFlow"]
const qElectrometer = Signal(get_gtk_property(sboxElectrometerFlow, "value", Float64))
const id11 = signal_connect(sboxElectrometerFlow, "value-changed") do widget, others...
     q = get_gtk_property(sboxElectrometerFlow, "value", Float64)
     push!(qElectrometer, q)
end

const id3 = signal_connect(startDiameterChanged, gui["StartDiameter"], "focus-out-event")
const id4 = signal_connect(endDiameterChanged, gui["EndDiameter"], "focus-out-event")

# Set up list store
const viewport = gui["tree"]
const listStore = GtkListStore(Int, String, String, String, String, String, String)
const treeView = GtkTreeView(GtkTreeModel(listStore))
const renderText = GtkCellRendererText()
const scrolledWindow = Gtk.ScrolledWindow()
const vAdjust = get_gtk_property(scrolledWindow, :vadjustment, GtkAdjustment)

const c0 = GtkTreeViewColumn("ID", renderText, Dict([("text", 0)]))
const c1 = GtkTreeViewColumn("Time (HH:MM)", renderText, Dict([("text", 1)]))
const c2 = GtkTreeViewColumn("RH (%)", renderText, Dict([("text", 2)]))
const c3 = GtkTreeViewColumn("Number (cm-3)", renderText, Dict([("text", 3)]))
const c4 = GtkTreeViewColumn("Area (μm2 cm-3)", renderText, Dict([("text", 4)]))
const c5 = GtkTreeViewColumn("Volume (μm3 cm-3)", renderText, Dict([("text", 5)]))
const c6 = GtkTreeViewColumn("CPC (cm-3)", renderText, Dict([("text", 6)]))

const selection =
    @> GAccessor.selection(treeView) GAccessor.mode(Gtk.GConstants.GtkSelectionMode.SINGLE)

