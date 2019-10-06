# Julia-SMPS-IM
Julia SMPS Instrument Manager: Asynchronous functional reactive programming for data acquition and instrument control: Example application to scanning mobility particle sizing.

Hardware requirements: Labjack U6 multifunction DAQ card, LJTick-DAC 0-10V 14 bit analog outputs, High Voltage Power Supply, 1-3 serial ports, 1-3 condensation particle counters, 1 differential mobility analyzer column. Optionally, 2 Rotronic RH sensors for the sheath and sample flow are read.

The software reads the condensation particle counters using pulse counting and serial ports. The software controls the high voltage applied to the center of the DMA column. 

Defaults, including flow rates and scan rates are set in the gui files. The files can be edited using the GTK glade tool.

Data inversion is performed using [DifferentialMobilityAnalyzers.jl](https://github.com/mdpetters/DifferentialMobilityAnalyzers.jl)

# Installation
Install package dependencies
```julia
pkg> add Gtk Reactive Colors DataFrames Printf Dates CSV JLD2 FileIO LibSerialPort Interpolations LinearAlgebra Statistics LambertW NumericIO
```

Provide user access to dialout group for serial communication
```shell
sudo usermod -a -G dialout $USER
sudo reboot
```

InspectDR
```julia
pkg> add https://github.com/mdpetters/InspectDR.jl
```
Note that this is a fork of the official InspectDR package that has the GTK sliders removed. 

Install [DifferentialMobilityAnalyzers.jl](https://github.com/mdpetters/DifferentialMobilityAnalyzers.jl)

Install [LabjackU6Library.jl](https://github.com/mdpetters/LabjackU6Library.jl)

# Additional Information
This code is being used at NC State University for SMPS data acquisition and inversion. The software is mature and stable, but not yet well-documented. Below is a copy of an abstract for a presention at the annual AAAR conference held in Portland, OR, 2019. 

Professional societies and funding agencies are moving towards open data policies that require publication of raw data and computer software used to generate results. Consequently, instrument control and data acquisition (DAQ) software ought to be shared with publication. Most manufacturers only distribute proprietary code in binary format with their instruments. Research groups that build new instruments often use proprietary special-domain languages such as LabVIEW to implement the DAQ software. Both models are unsuitable for publication and difficult to evaluate for correctness. Furthermore, DAQ software design principles are rarely debated in the scientific literature, thus slowing advances in instrument development. Here I show that functional reactive programming principles are well suited to construct reliable, efficient, and concise code for data acquisition and instrument control. The approach uses a textual syntax with a functional programming style, signal-based data structures, asynchronous event processing, and interfaces with a graphical user interface. To demonstrate the utility of the approach, free software to operate differential mobility analyzers (DMA) in scanning mode for size distribution measurement is shared. The code controls the instrument and acquires multiple data streams at two frequencies using a multifunction DAQ device and serial communication on a Linux platform. Raw DMA response functions are inverted in real time using the methodology described in Petters (2018, AS&T, doi:10.1080/02786826.2018.1530724). With moderate financial and time investment, the software can be used as is to operate a complete scanning mobility particle sizer system using a DMA column, high-voltage power supply, and detector. The software can log multiple auxiliary sensors and be adapted to build more elaborate programs controlling tandem DMA setups with complex duty cycles. The software design principles are general, portable to several common programming languages, and can be applied to a wide range of instrument automation scenarios.
