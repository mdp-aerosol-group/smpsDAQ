# parse_box functions read a text box and returns the formatted result
function parse_box(s::String, default::Float64)
	x = get_gtk_property(gui[s], :text, String)
	y = try parse(Float64,x) catch; y = default end
end

function parse_box(s::String, default::Int)
	x = get_gtk_property(gui[s], :text, String)
	y = try parse(Int,x) catch; y = default end
end

function parse_box(s::String, default::Missing)
	x = get_gtk_property(gui[s], :text, String)
	y = try parse(Float64,x) catch; y = missing end
end

function parse_box(s::String)
	x = get_gtk_property(gui[s], :active_id, String)
	y = Symbol(x)
end

function set_SMPS_config()
	(column == :TSI) && ((r₁,r₂,l) = (9.37e-3,1.961e-2,0.44369))
	(column == :HFDMA) && ((r₁,r₂,l) = (0.05,0.058,0.6))
	(column == :RDMA) && ((r₁,r₂,l) = (2.4e-3,50.4e-3,10e-3))
	form = (column == :RDMA) ? :radial : :cylindrical
	Λˢᵐᵖˢ = DMAconfig(t,p,qsa,qsh,r₁,r₂,l,leff,polarity,6,form) 
	z1,z2 = vtoz(Λˢᵐᵖˢ,10000.0), vtoz(Λˢᵐᵖˢ,10.0)
	δˢᵐᵖˢ = setupDMA(Λˢᵐᵖˢ, z1, z2, bins)
	Λˢᵐᵖˢ, δˢᵐᵖˢ
end

const Godot = @task _->false
const _Gtk = Gtk.ShortNames
const black = RGBA(0, 0, 0, 1)
const red = RGBA(0.8, 0.2, 0, 1)
const mblue = RGBA(0, 0, 0.8, 1)
const mgrey = RGBA(0.4, 0.4, 0.4, 1)
const lpm = 1.666666e-5
const lowerDchart = parse_box("LowerDchart", 5.0)
const upperDchart = parse_box("UpperDchart", 5.0)
const bufferlength = 400

const t = parse_box("TemperatureSMPS", 22.0)+273.15
const p = parse_box("PressureSMPS", 1001.0)*100.0
const qsh = parse_box("SheathFlowSMPS", 10.0)*lpm
const qsa = parse_box("SampleFlowSMPS", 1.0)*lpm
const leff = parse_box("EffectiveLength", 0.0)
const bins = parse_box("NumberOfBins", 120)
const τᶜ = parse_box("PlumbTime", 4.1)
const polarity = parse_box("ColumnPolaritySMPS")
const powerSupply = parse_box("DMAPowerSupply")
const column = parse_box("DMATypeSMPS")
const Λˢᵐᵖˢ, δˢᵐᵖˢ = set_SMPS_config()
const path = mapreduce(a->"/"*a,*,(pwd() |> x->split(x,"/"))[2:3])*"/Data/"

outfile = path*Dates.format(now(), "yyyymmdd_HHMM")*".csv"
const switch  = Reactive.Signal(false)
const useSMPS = Reactive.Signal(false)
const powerSMPS = Reactive.Signal(true)

const datestr = Reactive.Signal(Dates.format(now(), "yyyymmdd"))

global tenHz_df = DataFrame(Timestamp = DateTime[],
                            Unixtime = Float64[],
                            Int64time = Int64[],
                            LapseTime = String[],
					        state = Symbol[], 
					        voltageSet = Float64[],
					        currentDiameter = Float64[],
					        N1cpcCount = Float64[], 
							N2cpcCount = Float64[],
							N1cpcSerial = Union{Float64, Missing}[], 
							N2cpcSerial = Union{Float64, Missing}[])

global oneHz_df = DataFrame(Timestamp = DateTime[],
                            Unixtime = Float64[],
                            Int64time = Int64[],
                            LapseTime = String[],
							state = Symbol[], 
							powerSMPS = Bool[],
							VoltageSMPS = Float64[],
							currentDiameter = Float64[],
					        N1cpcSerial = Union{Float64, Missing}[], 
							N2cpcSerial = Union{Float64, Missing}[],
							RHsh = Union{Float64, Missing}[],
							Tsh = Union{Float64, Missing}[],
							Tdsh = Union{Float64, Missing}[],
							RHsa = Union{Float64, Missing}[],
							Tsa = Union{Float64, Missing}[],
							Tdsa = Union{Float64, Missing}[])


global inversionParameters = DataFrame(Timestamp = String[],
									   Ncpc = Union{Float64,Missing}[],
									   N = Float64[],
									   A = Float64[],
									   V = Float64[],
									   useCounts = Bool[],
									   converged = Bool[],
									   λopt = Float64[],
									   λfb = Float64[],
                                       L1 = Vector[],
									   L2 = Vector[],
									   λs = Vector[],
                                       ii = Int[])

global ℝ=SizeDistribution

global SizeDistribution_df = DataFrame(Timestamp = DateTime[],
                                          useCounts = Bool[],
                                          Response = SizeDistribution[],
										  Inverted = SizeDistribution[],
										  oneHz_df = DataFrame[],
										  tenHz_df = DataFrame[])
										  
global SizeDistribution_filename = Dates.format(now(), "yyyymmdd_HHMM")*".jld2"