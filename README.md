# Interactive Physics Engine
Final project for Microprocessors (E155) at Harvey Mudd College

Authored by https://github.com/Amigoyith and https://github.com/stuxf/

## FPGA

The code for our FPGA is included inside the [/FPGA](/fpga/) folder. The file structure is as seen there.

Some highlihgts are that the main (top-level) module can be found at [/FPGA/main.sv](/fpga/main.sv), the display driver can be found at [/FPGA/display.sv](/fpga/display.sv) and the physics engine can be found at [/FPGA/physics_engine.sv](/fpga/physics_engine.sv).

For the build process, we opted to use [APIO](https://github.com/FPGAwars/apio), an open source ecosystem for FPGA boards using the Yosys toolchain. This allowed us several advantages over Lattice Radiant, including much faster build times. APIO is designed to be very simple to install, the command is just the following:

```BASH
pip3 install apio
```

And this sets up everything you need.

One issue we ran into was that APIO does not support SystemVerilog. We ended up using [github.com/zachjs/sv2v](https://github.com/zachjs/sv2v), combined with APIO, which is why you'll actually see SystemVerilog files in our repository. So our process of uploading our code to our FPGA ended up looking something like this, converting all our SystemVerilog to one big Verilog file, before uploading it to our FPGA.

```BASH
sv2v *.sv > all.v
apio upload
```

## MCU

The code for our MCU is included inside the [/MCU](/MCU/) folder.

The code that describes the MCU's operation is included inside the [main.c](/MCU/main.c) file. The rest of the code is for interacting with our devices, and can be found in [lib](/MCU/lib/). Two of the new libs that we added were for communicating over I2C and with our MPU6050 controller, and their implementation can be found at [lib/MPU6050.c](/MCU/lib/MPU6050.c) and [lib/STM32L432KC_I2C.c](/MCU/lib/STM32L432KC_I2C.c)

## CAD

The CAD for our 3d printed parts is included inside the [/CAD](/CAD/) folder.