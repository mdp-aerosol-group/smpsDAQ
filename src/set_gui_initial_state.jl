style = :solid

plot4 = InspectDR.Plot2D(:log, :lin, title = "")
InspectDR.overwritefont!(plot4.layout, fontname = "Helvetica", fontscale = 1.2)
plot4.layout[:enable_legend] = true
plot4.layout[:halloc_legend] = 170
plot4.layout[:halloc_left] = 50
plot4.layout[:enable_timestamp] = false
plot4.layout[:length_tickmajor] = 10
plot4.layout[:length_tickminor] = 6
plot4.layout[:format_xtick] = InspectDR.TickLabelStyle(UEXPONENT)
plot4.layout[:frame_data] = InspectDR.AreaAttributes(
    line = InspectDR.line(style = :solid, color = black, width = 0.5),
)
plot4.layout[:line_gridmajor] = InspectDR.LineStyle(:solid, Float64(0.75), RGBA(0, 0, 0, 1))

plot4.xext = InspectDR.PExtents1D()
plot4.xext_full = InspectDR.PExtents1D(lowerDchart, upperDchart)

a = plot4.annotation
a.xlabel = "Diameter (nm)"
a.ylabels = ["Raw concentration (cm-3)"]
mp4, gplot4 = push_plot_to_gui!(plot4, gui["AerosolSizeDistribution2"], wnd)
wfrm = add(plot4, [0.0], [0.0], id = "Current Scan")
wfrm.line = line(color = black, width = 2, style = style)
wfrm = add(plot4, [0.0], [0.0], id = "Past Scan")
wfrm.line = line(color = mblue, width = 2, style = style)
wfrm = add(plot4, [0.0], [0.0], id = "Current D")
wfrm.line = line(color = black, width = 2, style = :solid)
wfrm = add(plot4, [0.0], [0.0], id = "Min D")
wfrm.line = line(color = black, width = 2, style = :solid)
wfrm = add(plot4, [0.0], [0.0], id = "Max D")
wfrm.line = line(color = black, width = 2, style = :solid)

graph = plot4.strips[1]
graph.grid = InspectDR.GridRect(vmajor = true, vminor = true, hmajor = true, hminor = true)

plot5 = InspectDR.Plot2D(:log, :lin, title = "")
InspectDR.overwritefont!(plot5.layout, fontname = "Helvetica", fontscale = 1.2)
plot5.layout[:enable_legend] = true
plot5.layout[:halloc_legend] = 170
plot5.layout[:halloc_left] = 50
plot5.layout[:enable_timestamp] = false
plot5.layout[:length_tickmajor] = 10
plot5.layout[:length_tickminor] = 6
plot5.layout[:format_xtick] = InspectDR.TickLabelStyle(UEXPONENT)
plot5.layout[:frame_data] = InspectDR.AreaAttributes(
    line = InspectDR.line(style = :solid, color = black, width = 0.5),
)
plot5.layout[:line_gridmajor] = InspectDR.LineStyle(:solid, Float64(0.75), RGBA(0, 0, 0, 1))

plot5.xext = InspectDR.PExtents1D()
plot5.xext_full = InspectDR.PExtents1D(lowerDchart, upperDchart)

a = plot5.annotation
a.xlabel = "Diameter (nm)"
a.ylabels = ["Inverted dN/dlnD (cm-3)"]
mp5, gplot5 = push_plot_to_gui!(plot5, gui["AerosolSizeDistribution1"], wnd)
wfrm = add(plot5, [0.0], [0.0], id = "Current Scan")
wfrm.line = line(color = black, width = 2, style = style)
wfrm = add(plot5, [0.0], [0.0], id = "Past Scan")
wfrm.line = line(color = mblue, width = 2, style = style)

graph = plot5.strips[1]
graph.grid = InspectDR.GridRect(vmajor = true, vminor = true, hmajor = true, hminor = true)

plotOpticaT = graph1(:lin)
plotOpticaT.layout[:halloc_legend] = 110
mpTemp, gplotOpticaT = push_plot_to_gui!(plotOpticaT, gui["housekeeping1"], wnd)
wfrm = add(plotOpticaT, [0.0], [22.0], id = "T1 (°C)")
wfrm.line = line(color = black, width = 2, style = style)
wfrm = add(plotOpticaT, [0.0], [22.0], id = "T2 (°C)")
wfrm.line = line(color = mblue, width = 2, style = style)
wfrm = add(plotOpticaT, [0.0], [22.0], id = "Td1 (°C)")
wfrm.line = line(color = red, width = 2, style = style)
wfrm = add(plotOpticaT, [0.0], [22.0], id = "Td2 (°C)")
wfrm.line = line(color = mgrey, width = 2, style = style)

plotParticle = graph1(:lin)
plotParticle.layout[:halloc_legend] = 110
mp3, gplotParticle = push_plot_to_gui!(plotParticle, gui["ParticleGraph"], wnd)
wfrm = add(plotParticle, [0.0], [0.0], id = "CPC #1")
wfrm.line = line(color = black, width = 2, style = style)
wfrm = add(plotParticle, [0.0], [0.0], id = "CPC #2")
wfrm.line = line(color = mblue, width = 2, style = style)
wfrm = add(plotParticle, [0.0], [0.0], id = "CPC #3")
wfrm.line = line(color = red, width = 2, style = style)

# a = pwd() |> x -> split(x, "/")
# path = mapreduce(a -> "/" * a, *, a[2:3]) * "/Data/"
# outfile = path * "yyyymmdd_hhmm.csv"
Gtk.set_gtk_property!(gui["DataFile"], :text, outfile)
Gtk.set_gtk_property!(gui["ScanNumber"], :text, "-1")
Gtk.set_gtk_property!(gui["ScanCounter"], :text, "1000")
Gtk.set_gtk_property!(gui["ScanState"], :text, "HOLD");
Gtk.set_gtk_property!(gui["setV"], :text, "0");

push!(treeView, c1, c2, c3, c4, c5, c6)
push!(scrolledWindow, treeView)
push!(viewport, scrolledWindow)

@_ map(GAccessor.resizable(_, true), [c1, c2, c3, c4, c5, c6])
@_ map(GAccessor.sort_column_id(_[2], _[1]), enumerate([c1, c2, c3, c4, c5, c6]))
@_ map(GAccessor.reorderable(_[2], _[1]), enumerate([c1, c2, c3, c4, c5, c6]))

# Set the three voltages as initial condition
set_voltage_SMPS("StartDiameter", "StartV")
set_voltage_SMPS("EndDiameter", "EndV")
