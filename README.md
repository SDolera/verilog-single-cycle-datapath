# Single-Cycle MIPS Processor on Cyclone V (5CSEMA5)

## Overview
This project implements a single-cycle MIPS-style processor in Verilog and deploys it on the Cyclone V FPGA (DE1-SoC, 5CSEMA5).

The design includes a fully integrated datapath and control unit capable of executing a subset of MIPS instructions in one clock cycle.

## Architecture Components
- Program Counter (PC)
- Instruction Memory
- Register File
- ALU
- Sign Extender
- Control Unit
- Data Memory
- Branch & Jump Logic

## Tools Used
- Verilog HDL
- Intel Quartus Prime
- ModelSim
- DE1-SoC Board (Cyclone V 5CSEMA5)

## Features
- Single-cycle execution model
- Separate datapath and control modules
- Synthesizable design
- On-board FPGA deployment

## Results
Successfully synthesized and deployed to Cyclone V FPGA.
Verified functionality using ModelSim waveform simulation.

## Folder Structure
- `src/` → Verilog modules
- `testbench/` → Simulation testbenches
- `docs/` → Architecture diagrams and results
