# + 
# Signals for SMPS control
# Setup scan logic and DAQ and Signals. 
# Generates Reactive signals and defines SMPS post-processing
# -

function smps_signals()
    holdTime, scanTime, flushTime, scanLength, startVoltage, endVoltage, c =
        scan_parameters()

    # Set SMPS states
    function state(currentTime)
        holdTime, scanTime, flushTime, scanLength, startVoltage, endVoltage, c =
            scan_parameters()
        state = @> get_gtk_property(gui["ManualStateSelection"], "active-id", String) Symbol
        scanState = "DONE"
        (currentTime <= scanLength) && (scanState = "FLUSH")
        (currentTime < scanTime + holdTime) && (scanState = "SCAN")
        (currentTime <= holdTime) && (scanState = "HOLD")
        scanState = (state == :SMPS) ? scanState : "CLASSIFIER"

        return scanState
    end

    # Set SMPS voltage
    function smps_voltage(t)
        holdTime, scanTime, flushTime, scanLength, startVoltage, endVoltage, c =
            scan_parameters()
        classifierV = @>> get_gtk_property(gui["ClassifierV"], :text, String) parse(Float64)
        (smps_scan_state.value == "HOLD") && (myV = startVoltage)
        (smps_scan_state.value == "SCAN") &&
            (myV = exp(log(startVoltage) + c * (t - holdTime)))
        (smps_scan_state.value == "FLUSH") && (myV = endVoltage)
        (smps_scan_state.value == "DONE") && (myV = endVoltage)
        (smps_scan_state.value == "CLASSIFIER") && (myV = classifierV)

        return myV
    end

    # Determine cleanup procedure once scan is done
    function smps_scan_termination(s)
        try
            delete!(tenHz_df, 1)
        catch
        end
        if length(tenHz_df[!, :state]) > 10
            current_file = Dates.format((tenHz_df[!, :Timestamp])[1], "yyyymmdd_HHMM")
            path1 = path * "Raw 10 Hz/" * datestr.value
            read(`mkdir -p $path1`)
            outfile = path1 * "/" * current_file * ".csv"
            tenHz_df |> CSV.write(outfile)
            set_gtk_property!(gui["DataFile"], :text, outfile)

            path2 = path * "Raw 1 Hz/" * datestr.value
            read(`mkdir -p $path2`)
            outfile = path2 * "/" * current_file * ".csv"
            oneHz_df |> CSV.write(outfile)

            path3 = path * "Processed/" * datestr.value
            read(`mkdir -p $path3`)
            outfile = path3 * "/" * SizeDistribution_filename.value

            # Query basic SMPS setup for storage
            t = parse_box("TemperatureSMPS", 22.0) + 273.15
            p = parse_box("PressureSMPS", 1001.0) * 100.0
            qsh = parse_box("SheathFlowSMPS", 10.0) * lpm
            qsa = parse_box("SampleFlowSMPS", 1.0) * lpm
            polarity = parse_box("ColumnPolaritySMPS")
            column = parse_box("DMATypeSMPS")
            τᶜ = parse_box("PlumbTime", 4.1)
            SMPSsetup = (t, p, qsh, qsa, polarity, column, τᶜ)
            useCounts = get_gtk_property(gui["UseCounts"], :state, Bool)

            # Compute inversion and L-curve (see Petters (2018), Notebooks 5 and 6)
            λ₁ = parse_box("LambdaLow", 0.05)
            λ₂ = parse_box("LambdaHigh", 0.05)
            N = @> rinv2(ℝ.value.N, δˢᵐᵖˢ, λ₁ = λ₁, λ₂ = λ₂) getfield(:N) clean
            𝕟 = SizeDistribution(
                [],
                ℝ.value.De,
                ℝ.value.Dp,
                ℝ.value.ΔlnD,
                N ./ ℝ.value.ΔlnD,
                N,
                :regularized,
            )

            # Plot the inverted data and L-curve
            addseries!(reverse(𝕟.Dp), reverse(𝕟.S), plot5, gplot5, 1, false, true)
            # Write DataFrames for processed data
            push!(
                inversionParameters,
                Dict(
                    :Timestamp => Dates.format((tenHz_df[!, :Timestamp])[1], "HH:MM"),
                    :Ncpc => mean(oneHz_df[!, :N2cpcSerial]),
                    :N => sum(𝕟.N),
                    :A => sum(π / 4.0 .* (𝕟.Dp ./ 1000.0) .^ 2 .* 𝕟.N),
                    :V => sum(π / 6.0 .* (𝕟.Dp ./ 1000.0) .^ 3 .* 𝕟.N),
                    :useCounts => useCounts,
                ),
            )

            push!(
                SizeDistribution_df,
                Dict(
                    :Timestamp => (tenHz_df[!, :Timestamp])[1],
                    :useCounts => useCounts,
                    :Response => deepcopy(ℝ.value),
                    :Inverted => deepcopy(𝕟),
                    :oneHz_df => deepcopy(oneHz_df),
                    :tenHz_df => deepcopy(tenHz_df),
                ),
            )

            @save outfile SizeDistribution_df δˢᵐᵖˢ Λˢᵐᵖˢ SMPSsetup inversionParameters

            # Print summary data to textbox
            ix = size(inversionParameters, 1)

            push!(smps_scan_number, smps_scan_number.value += 1)    # New scan
        end

        # reset response function and clear 1Hz and 10Hz DataFrames
        N = zeros(length(δˢᵐᵖˢ.Dp))
        push!(ℝ, SizeDistribution([[]], δˢᵐᵖˢ.De, δˢᵐᵖˢ.Dp, δˢᵐᵖˢ.ΔlnD, N, N, :response))
        delete!(tenHz_df, collect(1:length(tenHz_df[!, :Timestamp])))
        delete!(oneHz_df, collect(1:length(oneHz_df[!, :Timestamp])))
    end

    # Generate signals and connect with functions
    smps_elapsed_time = foldp(+, 0.0, tenHz)
    smps_scan_state = map(state, smps_elapsed_time)
    smps_scan_number = Signal(1)
    V = map(smps_voltage, smps_elapsed_time)
    Dp = map(v -> ztod(Λˢᵐᵖˢ, 1, vtoz(Λˢᵐᵖˢ, v)), V)
    termination = map(smps_scan_termination, filter(s -> s == "DONE", smps_scan_state))
    reset = map(
        s -> push!(smps_elapsed_time, 0.0),
        filter(t -> t > scanLength + 5.0, smps_elapsed_time),
    )
    smps_elapsed_time, smps_scan_state, smps_scan_number, termination, reset, V, Dp
end

# Read scan settings from GUI
function scan_parameters()
    holdTime = @>> get_gtk_property(gui["Hold"], :text, String) parse(Float64)
    scanTime = @>> get_gtk_property(gui["Scant"], :text, String) parse(Float64)
    flushTime = @>> get_gtk_property(gui["Flush"], :text, String) parse(Float64)
    startVoltage = @>> get_gtk_property(gui["StartV"], :text, String) parse(Float64)
    endVoltage = @>> get_gtk_property(gui["EndV"], :text, String) parse(Float64)
    scanLength = holdTime + scanTime + flushTime
    c = log(endVoltage / startVoltage) / (scanTime)

    return holdTime, scanTime, flushTime, scanLength, startVoltage, endVoltage, c
end
