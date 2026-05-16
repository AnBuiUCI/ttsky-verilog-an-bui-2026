![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Swarm Robot Finite State Machine
This project implements a finite state machine (FSM) in Verilog for a simplified swarm microrobot drug delivery system submitted to Tiny Tapeout.

The design models autonomous microrobot behavior for detecting blood clots, coordinating with nearby robots through communication signals, releasing a drug payload, and driving motors to move away from clot regions.

## Features

- Blood clot detection input
- Swarm communication using RX/TX signaling
- Internal drug availability memory
- Drug release control output
- Multi-state finite state machine architecture
- Four DC motor control outputs
- Tiny Tapeout compatible RTL design

## System Overview

The robot operates using two external inputs:

- `clot_detected` — local sensor detects a blood clot
- `clot_nearby` — RX signal indicating another nearby robot detected a clot

The FSM transitions between four states:

1. **RANDOM_WALK**
   - Default idle behavior

2. **RELEASE_DRUG**
   - Triggered when a clot is detected and drug is available
   - Releases drug payload
   - Broadcasts clot detected TX signal
   - Clears internal drug memory

3. **CLOT_NO_DRUG**
   - Triggered when a clot is detected after drug depletion
   - Broadcasts clot detected TX signal
   - Broadcasts no-drug TX signal

4. **WALK_AWAY**
   - Activates four motor outputs
   - Moves robot away from clot region
Moves robot away from clot region
