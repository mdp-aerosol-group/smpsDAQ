#!/bin/julia

config_file = "gui/TSI3080_1600x900.glade"
include("smps.jl")
#wait(Godot) 
#

ta = Dates.format(now(), "HH:MM")
mRH = formatted(20.0, :SI, ndigits = 3)
mN = formatted(311.0, :SI, ndigits = 4)
mA = formatted(250.0, :SI, ndigits = 4)
mV = formatted(20.0, :SI, ndigits = 3)
mCPC = formatted(10, :SI, ndigits = 4)

push!(listStore,(ta, mRH, mN, mA, mV, mCPC))

map(x->insert!(listStore,1,(Dates.format(now(), "HH:MM"), mRH, mN, mA, mV, mCPC)), 1:10)

set_gtk_property!(vAdjust, :value, 0.0)


