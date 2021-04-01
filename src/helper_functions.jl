# +
# helper_functions.jl
#
# collection of functions
#
# function push_plot_to_gui!(plot, box, wnd)
# -- adds the plot to a Gtk box located in a window
#
# function refreshplot(gplot::InspectDR.GtkPlot)
# -- refreshes the Gtk plot on screen
#
# function addpoint!(x::Float64,y::Float64,plot::InspectDR.Plot2D,
#  				     gplot::InspectDR.GtkPlot)
# -- adds an x/y point to the plot
#


function parse_missing(N)
    return str = try
        @sprintf("%.1f", N)
    catch
        "missing"
    end
end

function parse_missing1(N)
    return str = try
        @sprintf("%.2f", N)
    catch
        "missing"
    end
end

# parse_box functions read a text box and returns the formatted result
function parse_box(s::String, default::Float64)
    x = get_gtk_property(gui[s], :text, String)
    y = try
        parse(Float64, x)
    catch
        y = default
    end
end

function parse_box(s::String, default::Int)
    x = get_gtk_property(gui[s], :text, String)
    y = try
        parse(Int, x)
    catch
        y = default
    end
end

function parse_box(s::String, default::Missing)
    x = get_gtk_property(gui[s], :text, String)
    y = try
        parse(Float64, x)
    catch
        y = missing
    end
end

function parse_box(s::String)
    x = get_gtk_property(gui[s], :active_id, String)
    y = Symbol(x)
end

function set_SMPS_config()
    (column == :TSI) && ((r₁, r₂, l) = (9.37e-3, 1.961e-2, 0.44369))
    (column == :HFDMA) && ((r₁, r₂, l) = (0.05, 0.058, 0.6))
    (column == :RDMA) && ((r₁, r₂, l) = (2.4e-3, 50.4e-3, 10e-3))
    form = (column == :RDMA) ? :radial : :cylindrical
    Λˢᵐᵖˢ = DMAconfig(t, p, qsa, qsh, r₁, r₂, l, leff, polarity, 6, form)
    z1, z2 = vtoz(Λˢᵐᵖˢ, 10000.0), vtoz(Λˢᵐᵖˢ, 10.0)
    δˢᵐᵖˢ = setupDMA(Λˢᵐᵖˢ, z1, z2, bins)
    Λˢᵐᵖˢ, δˢᵐᵖˢ
end


function powerSMPSswitch(widget::Gtk.GtkSwitchLeaf, state::Bool)
    push!(powerSMPS, state)
end

function reset_scan()
    set_voltage_SMPS("StartDiameter", "StartV")
    set_voltage_SMPS("EndDiameter", "EndV")
    set_voltage_SMPS("ClassifierDiameterSMPS", "ClassifierV")

    a = pwd() |> x -> split(x, "/")
    path = mapreduce(a -> "/" * a, *, a[2:3]) * "/Data/"
    outfile = path * "yyyymmdd_hhmm.csv"
    Gtk.set_gtk_property!(gui["DataFile"], :text, outfile)
    Gtk.set_gtk_property!(gui["ScanNumber"], :text, "0")
    Gtk.set_gtk_property!(gui["ScanCounter"], :text, "1000")
    Gtk.set_gtk_property!(gui["ScanState"], :text, "HOLD")
    Gtk.set_gtk_property!(gui["setV"], :text, "0")
end

# if StartDiameter changes then Recompute Voltage
function startDiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
    set_voltage_SMPS("StartDiameter", "StartV")
end

# if endDiameter changes then Recompute Voltage
function endDiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
    set_voltage_SMPS("EndDiameter", "EndV")
end

function set_voltage_SPINBox(source::GtkSpinButtonLeaf, destination::String)
    D = get_gtk_property(sbox, "value", Float64)
    V = ztov(Λˢᵐᵖˢ, dtoz(Λˢᵐᵖˢ, D * 1e-9))
    if V > 10000.0
        V = 10000.0
        D = ztod(Λˢᵐᵖˢ, 1, vtoz(Λˢᵐᵖˢ, 10000.0))
        set_gtk_property!(sbox, "value", round(D, digits = 0))
    elseif V < 10.0
        V = 10.0
        D = ztod(Λˢᵐᵖˢ, 1, vtoz(Λˢᵐᵖˢ, 10.0))
        set_gtk_property!(sbox, "value", round(D, digits = 0))
    end
    set_gtk_property!(gui[destination], :text, @sprintf("%0.0f", V))
end

function set_voltage_SMPS(source::String, destination::String)
    D = parse_box(source, 100.0)
    (D == 100.0) && set_gtk_property!(gui[source], :text, "100")
    V = ztov(Λˢᵐᵖˢ, dtoz(Λˢᵐᵖˢ, D * 1e-9))
    if V > 10000.0
        V = 10000.0
        D = ztod(Λˢᵐᵖˢ, 1, vtoz(Λˢᵐᵖˢ, 10000.0))
        set_gtk_property!(gui[source], :text, @sprintf("%0.0f", D))
    elseif V < 10.0
        V = 10.0
        D = ztod(Λˢᵐᵖˢ, 1, vtoz(Λˢᵐᵖˢ, 10.0))
        set_gtk_property!(gui[source], :text, @sprintf("%0.0f", D))
    end
    set_gtk_property!(gui[destination], :text, @sprintf("%0.0f", V))
end


function graph1(yaxis)
    plot = InspectDR.transientplot(yaxis, title = "")
    InspectDR.overwritefont!(plot.layout, fontname = "Helvetica", fontscale = 1.2)
    plot.layout[:enable_legend] = true
    plot.layout[:halloc_legend] = 170
    plot.layout[:halloc_left] = 50
    plot.layout[:enable_timestamp] = false
    plot.layout[:length_tickmajor] = 10
    plot.layout[:length_tickminor] = 6
    plot.layout[:format_xtick] = InspectDR.TickLabelStyle(UEXPONENT)
    plot.layout[:frame_data] = InspectDR.AreaAttributes(
        line = InspectDR.line(style = :solid, color = black, width = 0.5),
    )
    plot.layout[:line_gridmajor] =
        InspectDR.LineStyle(:solid, Float64(0.75), RGBA(0, 0, 0, 1))

    plot.xext = InspectDR.PExtents1D()
    plot.xext_full = InspectDR.PExtents1D(0, 205)

    a = plot.annotation
    a.xlabel = ""
    a.ylabels = [""]

    return plot
end


# -- adds an x/y point to the plot
function addpoint!(
    x::Float64,
    y::Float64,
    plot::InspectDR.Plot2D,
    gplot::InspectDR.GtkPlot,
    strip::Int,
    autoscale::Bool,
)

    push!(plot.data[strip].ds.x, x)
    push!(plot.data[strip].ds.y, y)
    cut = plot.data[strip].ds.x[end] - bufferlength
    ii = plot.data[strip].ds.x .<= cut
    deleteat!(plot.data[strip].ds.x, ii)
    deleteat!(plot.data[strip].ds.y, ii)
    plot.xext = InspectDR.PExtents1D()
    plot.xext_full =
        InspectDR.PExtents1D(plot.data[strip].ds.x[1], plot.data[strip].ds.x[end])

    if autoscale == true
        miny, maxy = Float64[], Float64[]
        for x in plot.data
            push!(miny, minimum(x.ds.y))
            push!(maxy, maximum(x.ds.y))
        end
        miny = minimum(miny)
        maxy = maximum(maxy)
        graph = plot.strips[1]
        graph.yext = InspectDR.PExtents1D()
        graph.yext_full = InspectDR.PExtents1D(miny, maxy)
    end

    refreshplot(gplot)
end

function addseries!(
    x::Array{Float64},
    y::Array{Float64},
    plot::InspectDR.Plot2D,
    gplot::InspectDR.GtkPlot,
    strip::Int,
    autoscalex::Bool,
    autoscaley::Bool,
)

    plot.data[strip].ds.x = x
    plot.data[strip].ds.y = y
    if autoscaley == true
        miny, maxy = Float64[], Float64[]
        for x in plot.data
            push!(miny, minimum(x.ds.y))
            push!(maxy, maximum(x.ds.y))
        end
        miny = minimum(miny)
        maxy = maximum(maxy)
        graph = plot.strips[1]
        graph.yext = InspectDR.PExtents1D()
        graph.yext_full = InspectDR.PExtents1D(miny, maxy)
    end

    if autoscalex == true
        minx, maxx = Float64[], Float64[]
        for x in plot.data
            push!(minx, minimum(x.ds.x))
            push!(maxx, maximum(x.ds.x))
        end
        minx = minimum(minx)
        maxx = maximum(maxx)
        plot.xext = InspectDR.PExtents1D()
        plot.xext_full = InspectDR.PExtents1D(minx, maxx)
    end

    refreshplot(gplot)
end
# -- adds the plot to a Gtk box located in a window
function push_plot_to_gui!(plot::InspectDR.Plot2D, box::GtkBoxLeaf, wnd::GtkWindowLeaf)

    mp = InspectDR.Multiplot()
    InspectDR._add(mp, plot)
    grd = Gtk.Grid()
    Gtk.set_gtk_property!(grd, :column_homogeneous, true)
    status = _Gtk.Label("")
    push!(box, grd)
    gplot = InspectDR.GtkPlot(false, wnd, grd, [], mp, status)
    InspectDR.sync_subplots(gplot)
    return mp, gplot
end

# -- setup of the frame for a particular GUI plot
# Traced from InspectDR source code without title refresh
function refreshplot(gplot::InspectDR.GtkPlot)
    if !gplot.destroyed
        set_gtk_property!(gplot.grd, :visible, false)
        InspectDR.sync_subplots(gplot)
        for sub in gplot.subplots
            InspectDR.render(sub, refreshdata = true)
            Gtk.draw(sub.canvas)
        end
        set_gtk_property!(gplot.grd, :visible, true)
        Gtk.showall(gplot.grd)
        sleep(eps(0.0))
    end
end
