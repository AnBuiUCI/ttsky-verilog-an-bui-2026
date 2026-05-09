<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements a finite state machine (FSM) for a simplified swarm microrobot drug delivery system. The design detects blood clots, communicates clot information to nearby robots, and controls drug release and motor movement behavior.

The system uses two external inputs:

clot_detected (ui_in[0]) — local blood clot detection sensor
clot_nearby (ui_in[1]) — RX communication signal indicating another nearby robot detected a clot

The FSM has four states:

RANDOM_WALK
Default idle state where the robot moves normally.
RELEASE_DRUG
Triggered when a clot is locally detected and the robot still contains drug.
The robot:
releases the drug
transmits a clot detected TX signal
permanently clears its internal drug memory
CLOT_NO_DRUG
Triggered when a clot is detected after the drug has already been used.
The robot:
transmits clot detected TX
transmits no-drug TX
does not release drug
WALK_AWAY
Triggered after clot detection or when a nearby clot RX signal is received.
All four motor outputs are enabled to move the robot away from the clot region.

The design internally stores whether the robot still contains drug using a register initialized during reset.

## How to test

1. Apply reset (rst_n = 0) to initialize the system.
The robot starts with drug available.
uo_out[7] should become HIGH.

2. Set ui_in[1] = 1 to simulate a nearby clot RX signal.
The FSM enters WALK_AWAY.
Motor outputs uo_out[3:6] become HIGH.

3. Set ui_in[0] = 1 while drug is available.
uo_out[0] becomes HIGH to release drug.
uo_out[1] becomes HIGH to transmit clot detected TX.
After drug release, uo_out[7] becomes LOW.

4. Set ui_in[0] = 1 again after drug is used.
uo_out[0] remains LOW.
uo_out[1] remains HIGH.
uo_out[2] becomes HIGH to transmit no-drug TX.

## External hardware

No external hardware used in project
