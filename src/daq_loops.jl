# daq_loops.jl 
# List of data acquisition loops 
#
# oneHz_smps_loop      # 1Hz loop for SMPS graphs/Processing
# tenHz_smps_loop      # 10Hz loop for Labjack DAQ, GUI Texboxes, 10Hz data file
# oneHz_generic_loop   # 1Hz loop for generic DAQ (cpc_io, te_io)
# oneHz_data_file      # 1Hz loop for writing 1Hz data file

function oneHz_smps_loop()
    # -    
    # SMPS shifting and inversion
    state = deepcopy(tenHz_df[!, :state])
    Dp = deepcopy(tenHz_df[!, :currentDiameter])
    useCounts = get_gtk_property(gui["UseCounts"], :state, Bool)
    N =
        (useCounts == true) ? deepcopy(tenHz_df[!, :N1cpcCount]) :
        deepcopy(tenHz_df[!, :N1cpcSerial])
    τᶜ = get_gtk_property(gui["PlumbTime"], :text, String) |> x -> parse(Float64, x)
    τserial = get_gtk_property(gui["SerialDelay"], :text, String) |> x -> parse(Float64, x)
    (useCounts == false) && (τᶜ += τserial)
    τ = parse_box("BeamTransitTime", 4.0)

    correct = @. x ->
        -lambertw(-x * flowRate1 * 16.666τ * 1e-6, 0) / (flowRate1 * 16.6666 * τ * 1e-6)
    currentDiameter =
        get_gtk_property(gui["currentD"], :text, String) |> x -> parse(Float64, x)
    if length(N[state.==:SCAN]) > τᶜ * 10 + 1
        N = circshift(N, Int(round(-τᶜ * 10)))
        N = N[(state.==:SCAN).|(state.==:FLUSH)]
        if (useCounts == true)
            N = try
                correct(N)
            catch
                N
            end
        end
        Dp = Dp[(state.==:SCAN).|(state.==:FLUSH)]
        mDp = reverse(Dp[1:end-Int(round(τᶜ * 10))])
        mN = reverse(N[1:end-Int(round(τᶜ * 10))])

        push!(ℝ, resample((mDp, mN), (δˢᵐᵖˢ.Dp, δˢᵐᵖˢ.De)))

        plot4.data[1].ds.x = reverse(ℝ.value.Dp)
        plot4.data[1].ds.y = reverse(ℝ.value.N)
        miny, maxy = Float64[], Float64[]
        for x in plot4.data[1:2]
            push!(miny, minimum(skipmissing(x.ds.y)))
            push!(maxy, maximum(skipmissing(x.ds.y)))
        end
        miny = minimum(miny)
        maxy = maximum(maxy)

        plot4.data[3].ds.x = [currentDiameter, currentDiameter]
        plot4.data[3].ds.y = [miny, maxy]
        maxD = @>> get_gtk_property(gui["StartDiameter"], :text, String) parse(Float64)
        minD = @>> get_gtk_property(gui["EndDiameter"], :text, String) parse(Float64)
        plot4.data[4].ds.x = [minD, minD]
        plot4.data[4].ds.y = [miny, maxy]
        plot4.data[5].ds.x = [maxD, maxD]
        plot4.data[5].ds.y = [miny, maxy]
        graph = plot4.strips[1]
        graph.yext = InspectDR.PExtents1D()
        graph.yext_full = InspectDR.PExtents1D(miny, maxy)
        refreshplot(gplot4)
    end
end

function tenHz_smps_loop()
    # - 
    # This function executes @10 Hz during SMPS state
    # It provides Labjack DAQ, populates GUI Texbox, and generates a 10 Hz data file
    # -

    # Acquisition
    polarity = get_gtk_property(gui["ColumnPolaritySMPS"], "active-id", String) |> Symbol
    powerSwitch = get_gtk_property(gui["UltravoltEnableSMPS"], :state, Bool)
    AIN, Tk, rawcount, count = labjack_signals.value # Unpack signals

    voltageReadPositive = AIN[4] * 1000.0
    currentReadPositive = -AIN[3] * 0.167 * 1000.0
    voltageReadNegative = AIN[2] * 1000.0
    currentReadNegative = -AIN[1] * 0.167 * 1000.0

    N1cpcCount = count[1] / tenHz.value / (flowRate1 * 16.6666)  # Compute concentration
    N2cpcCount = count[2] / tenHz.value / (flowRate2 * 16.6666)  # Compute concentration

    # Dump to GUI
    set_gtk_property!(gui["Ncounts1"], :text, @sprintf("%0.1f", N1cpcCount))
    set_gtk_property!(gui["Ncounts2"], :text, @sprintf("%0.1f", N2cpcCount))

    # Convert AIN signal to RH,T,P for channels 
    channel = parse_box("SheathAIN", -1)
    RH1, T1, Td1 =
        (channel == -1) ? (missing, missing, missing) :
        AIN2HC(AIN, channel + 1, channel + 2)
    set_gtk_property!(gui["RHsaFreezer1"], :text, parse_missing(RH1))
    set_gtk_property!(gui["TsaFreezer1"], :text, parse_missing(T1))
    set_gtk_property!(gui["TdsaFreezer1"], :text, parse_missing(Td1))

    # Convert AIN signal to RH,T,P 
    channel = parse_box("SampleAIN", -1)
    RH2, T2, Td2 =
        (channel == -1) ? (missing, missing, missing) :
        AIN2HC(AIN, channel + 1, channel + 2)
    set_gtk_property!(gui["RHsa1"], :text, parse_missing(RH2))
    set_gtk_property!(gui["Tsa1"], :text, parse_missing(T2))
    set_gtk_property!(gui["Tdsa1"], :text, parse_missing(Td2))

    # Write signals to GUI
    set_gtk_property!(gui["ScanCounter"], :text, @sprintf("%.1f", smps_elapsed_time.value))
    set_gtk_property!(gui["ScanNumber"], :text, @sprintf("%i", smps_scan_number.value))
    set_gtk_property!(gui["ScanState"], :text, smps_scan_state.value)
    set_gtk_property!(gui["setV"], :text, @sprintf("%.1f", V.value))
    set_gtk_property!(gui["currentD"], :text, @sprintf("%.1f", Dp.value))

    # Write data to file
    ts = now()     # Generate current time stamp
    push!(
        tenHz_df,
        Dict(
            :Timestamp => ts,
            :Unixtime => datetime2unix(ts),
            :Int64time => Dates.value(ts),
            :LapseTime => @sprintf("%.3f", smps_elapsed_time.value),
            :state => Symbol(smps_scan_state.value),
            :voltageSet => V.value,
            :currentDiameter => Dp.value,
            :N1cpcCount => N1cpcCount,
            :N2cpcCount => N2cpcCount,
            :N1cpcSerial => parse_box("Nserial1", missing),
            :N2cpcSerial => parse_box("Nserial2", missing),
        ),
    )
end

function oneHz_generic_loop()
    t = main_elapsed_time.value

    # CPC I/O
    Nserial1 = readCPC(port1, CPCType1, flowRate1)
    Nserial2 = readCPC(port2, CPCType2, flowRate2)

    set_gtk_property!(gui["Nserial1"], :text, parse_missing(Nserial1))
    set_gtk_property!(gui["Nserial2"], :text, parse_missing(Nserial2))
    (typeof(Nserial1) == Missing) ||
        addpoint!(t, Nserial1, plotParticle, gplotParticle, 1, true)
    (typeof(Nserial2) == Missing) ||
        addpoint!(t, Nserial2, plotParticle, gplotParticle, 2, true)

    # Rotronic RH Sensor
    T1s = get_gtk_property(gui["TsaFreezer1"], :text, String)
    T1 = (T1s == "missing") ? missing : parse(Float64, T1s)
    Tdew_Rot1 = get_gtk_property(gui["TdsaFreezer1"], :text, String)
    Tdew_Rot1 = (T1s == "missing") ? missing : parse(Float64, Tdew_Rot1)

    T2s = get_gtk_property(gui["Tsa1"], :text, String)
    T2 = (T2s == "missing") ? missing : parse(Float64, T2s)
    Tdew_Rot2 = get_gtk_property(gui["Tdsa1"], :text, String)
    Tdew_Rot2 = (T2s == "missing") ? missing : parse(Float64, Tdew_Rot2)

    (typeof(T1) == Missing) || addpoint!(t, T1, plotOpticaT, gplotOpticaT, 1, true)
    (typeof(T2) == Missing) || addpoint!(t, T2, plotOpticaT, gplotOpticaT, 2, true)
    (typeof(T1) == Missing) || addpoint!(t, Tdew_Rot1, plotOpticaT, gplotOpticaT, 3, true)
    (typeof(T2) == Missing) || addpoint!(t, Tdew_Rot2, plotOpticaT, gplotOpticaT, 4, true)
end

function oneHz_data_file()
    # Write data to file
    ts = now()     # Generate current time stamp

    push!(
        oneHz_df,
        Dict(
            :Timestamp => ts,
            :Unixtime => datetime2unix(ts),
            :Int64time => Dates.value(ts),
            :LapseTime => @sprintf("%.3f", main_elapsed_time.value),
            :state => Symbol(smps_scan_state.value),
            :powerSMPS => powerSMPS.value,
            :VoltageSMPS => V.value,
            :currentDiameter => Dp.value,
            :N1cpcSerial => parse_box("Nserial1", missing),
            :N2cpcSerial => parse_box("Nserial2", missing),
            :RHsh => parse_box("RHsaFreezer1", missing),
            :Tsh => parse_box("TsaFreezer1", missing),
            :Tdsh => parse_box("TdsaFreezer1", missing),
            :RHsa => parse_box("RHsa1", missing),
            :Tsa => parse_box("Tsa1", missing),
            :Tdsa => parse_box("Tdsa1", missing),
        ),
    )
end

function resample((mDp, mN), (newDp, newDe))
    ΔlnD = log.(newDe[1:end-1] ./ newDe[2:end])
    R = Float64[]
    for i = 1:length(newDe)-1
        ii = (mDp .<= newDe[i]) .& (mDp .> newDe[i+1])
        un = mDp[ii]
        c = mN[ii]
        Nm = length(c) > 0 ? mean(c) : 0
        push!(R, Nm)
    end
    return SizeDistribution([[]], newDe, newDp, ΔlnD, R ./ ΔlnD, R, :response)
end
