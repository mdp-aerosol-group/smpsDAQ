function calibrateVoltage(v)
    useCal = get_gtk_property(gui["UseCalibration"], :state, Bool)
    c = get_gtk_property(gui["PowersupplyCalibrationFunction"], :text, String) |> Meta.parse
    calV = eval(c)
    calV = (calV > 0) ? calV : 0.0
    calV = (useCal == true) ? calV : v
    vsig = (powerSupply == :Ultravolt) ? getVdac(calV, polarity, true) : v / 1000.0
end

# Convert voltage to signal voltage for Ultravolt power supply
function getVdac(setV::Float64, polarity::Symbol, powerSwitch::Bool)
    (setV > 0.0) || (setV = 0.0)
    (setV < 10000.0) || (setV = 10000.0)

    if polarity == :-
        # Negative power supply +0.36V = -10kV, 5V = 0kV
        m = 10000.0 / (0.36 - 5.03)
        b = 10000.0 - m * 0.36
        setVdac = (setV - b) / m
        if setVdac < 0.36
            setVdac = 0.36
        elseif setVdac > 5.1
            setVdac = 5.1
        end
        if powerSwitch == false
            setVdac = 5.0
        end
    elseif polarity == :+
        # Positive power supply +0V = 0kV, 4.64V = 0kV
        m = 10000.0 / (4.64 - 0)
        b = 0
        setVdac = (setV - b) / m
        if setVdac < 0.0
            setVdac = 0.0
        elseif setVdac > 4.64
            setVdac = 4.64
        end
        if powerSwitch == false
            setVdac = 0.0
        end
    end
    return setVdac
end
