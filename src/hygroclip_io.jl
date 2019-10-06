# + 
# Functions to handle hygroclip HC2 sensor
# -

# Compute Hygroclip T and RH from AIN array
function AIN2HC(AIN,i,j)
    RH = AIN[i]*100.0
	T = AIN[j]*100.0 - 40.0
    Td = Tdew(T,RH)
    RH, T, Td
end

# Compute dewpoint Temp from T and RH
function Tdew(T::Float64, RH::Float64)
	a,b,c,d = 6.1121,18.678,257.14,234.5
    γ = try
        log(RH/100.0 * exp((b-T/d)*(T/(c+T))))
    catch 
        NaN
    end
	c*γ/(b-γ)
end

