sbox = gui["mainWindow"]
ids = signal_connect(sbox, "destroy") do widget, others...
	schedule(Godot)         # terminate the script
end

function globalDAQswitch(widget::Gtk.GtkSwitchLeaf, state::Bool)
	push!(switch, state)
	push!(main_elapsed_time, 0.0)
	j1_SizeDistribution_filename = Dates.format(now(), "yyyymmdd_HHMM")*".jld2"
	try; deleterows!(j1_SizeDistribution_df,1); catch; end;
	(state == false) && (reset_scan())
	(state == false) && push!(useSMPS,false)
end
id1 = signal_connect(globalDAQswitch, gui["globalDAQswitch"], "state-set")

function powerSMPSswitch(widget::Gtk.GtkSwitchLeaf, state::Bool)
	push!(powerSMPS,state)
end
id2 = signal_connect(powerSMPSswitch, gui["UltravoltEnableSMPS"], "state-set")

function reset_scan()
	set_voltage_SMPS("StartDiameter", "StartV")
	set_voltage_SMPS("EndDiameter", "EndV")
	set_voltage_SMPS("ClassifierDiameterSMPS", "ClassifierV")

	a= pwd() |> x->split(x,"/")
	path = mapreduce(a->"/"*a,*,a[2:3])*"/Data/"
	outfile = path*"yyyymmdd_hhmm.csv"
	Gtk.set_gtk_property!(gui["DataFile"],:text,outfile)
	Gtk.set_gtk_property!(gui["ScanNumber"], :text, "0")
	Gtk.set_gtk_property!(gui["ScanCounter"], :text, "1000")
	Gtk.set_gtk_property!(gui["ScanState"], :text, "HOLD");
	Gtk.set_gtk_property!(gui["setV"], :text, "0");
end

# if StartDiameter changes then Recompute Voltage
function startDiameterChanged(widget::GtkEntryLeaf,
							  EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("StartDiameter", "StartV")
end

# if endDiameter changes then Recompute Voltage
function endDiameterChanged(widget::GtkEntryLeaf,
							EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("EndDiameter", "EndV")
end

# if endDiameter changes then Recompute Voltage
# function SMPSDiameterChanged(widget::GtkEntryLeaf,
# 								   EventAny::Gtk.GdkEventAny)
# 	set_voltage_SMPS("ClassifierDiameterSMPS", "ClassifierV")
# end

function set_voltage_SPINBox(source::GtkSpinButtonLeaf, destination::String)
	D = get_gtk_property(sbox, "value", Float64)
	V = ztov(Λˢᵐᵖˢ,dtoz(Λˢᵐᵖˢ,D*1e-9))
	if V > 10000.0
		V = 10000.0
		D = ztod(Λˢᵐᵖˢ,1,vtoz(Λˢᵐᵖˢ,10000.0))
		set_gtk_property!(sbox, "value", round(D,digits=0))
	elseif V < 10.0
		V = 10.0
		D = ztod(Λˢᵐᵖˢ,1,vtoz(Λˢᵐᵖˢ,10.0))
		set_gtk_property!(sbox, "value", round(D,digits=0))
	end
	set_gtk_property!(gui[destination], :text, @sprintf("%0.0f", V))
end

sbox = gui["ClassifierDiameter"]
ids = signal_connect(sbox, "value-changed") do widget, others...
	set_voltage_SPINBox(sbox, "ClassifierV")
end
set_voltage_SPINBox(sbox, "ClassifierV")


function set_voltage_SMPS(source::String, destination::String)
	D = parse_box(source, 100.0)
	(D == 100.0) && set_gtk_property!(gui[source], :text, "100")
	V = ztov(Λˢᵐᵖˢ,dtoz(Λˢᵐᵖˢ,D*1e-9))
	if V > 10000.0
		V = 10000.0
		D = ztod(Λˢᵐᵖˢ,1,vtoz(Λˢᵐᵖˢ,10000.0))
		set_gtk_property!(gui[source], :text, @sprintf("%0.0f", D))
	elseif V < 10.0
		V = 10.0
		D = ztod(Λˢᵐᵖˢ,1,vtoz(Λˢᵐᵖˢ,10.0))
		set_gtk_property!(gui[source], :text, @sprintf("%0.0f", D))
	end
	set_gtk_property!(gui[destination], :text, @sprintf("%0.0f", V))
end


id3 = signal_connect(startDiameterChanged, gui["StartDiameter"], 
					 "focus-out-event")
id4 = signal_connect(endDiameterChanged, gui["EndDiameter"], 
					 "focus-out-event")
id10 = signal_connect(powerSMPSswitch, gui["UltravoltEnableSMPS"], "state-set")

# Set the three voltages as initial condition
set_voltage_SMPS("StartDiameter", "StartV")
set_voltage_SMPS("EndDiameter", "EndV")
