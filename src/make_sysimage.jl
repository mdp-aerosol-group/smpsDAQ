using PackageCompiler

create_sysimage(
    [
        :Gtk,
        :InspectDR,
        :Reactive,
        :Colors,
        :DataFrames,
        :Printf,
        :Dates,
        :CSV,
        :JLD2,
        :FileIO,
        :LibSerialPort,
        :Interpolations,
        :Statistics,
        :LambertW,
        :LinearAlgebra,
        :Lazy,
        :NumericIO,
        :Underscores,
        :DataStructures,
        :DifferentialMobilityAnalyzers,
        :RegularizationTools,
    ],
    sysimage_path = "sys_daq.so",
    precompile_execution_file = "startup.jl",
)
