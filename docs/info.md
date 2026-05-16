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

1. Apply reset (rst_n = 0, then rst_n = 1). The FSM initializes to RANDOM_WALK with the drug loaded. All uo_out bits are 0.

2. Hold idle (ui_in = 0) for one clock cycle. The FSM remains in RANDOM_WALK. All uo_out bits stay 0. This confirms no spurious transitions occur.

3. Set ui_in\[0\] = 1 to simulate a local clot detection while the drug is still available. The FSM transitions to RELEASE_DRUG. uo_out\[0\] goes HIGH (drug release command). uo_out\[1\] goes HIGH (clot detected TX). uo_out[2] remains LOW because the drug is still present during this cycle. Motors remain off.

4. Next clock cycle (clear ui_in). The FSM transitions to WALK_AWAY and contains_drug clears to 0. uo_out\[0\] and uo_out\[1\] go LOW. uo_out\[2\] goes HIGH (no drug TX). uo_out\[3\] through uo_out\[6\] go HIGH (all four motors on).

5. Next clock cycle. The FSM returns to RANDOM_WALK. Motors turn off. uo_out\[2\] remains HIGH because the drug is permanently gone.

6. Set ui_in\[0\] = 1 again to detect a clot without any drug. The FSM enters CLOT_NO_DRUG. uo_out\[0\] stays LOW (no drug to release). uo_out\[1\] goes HIGH (clot detected TX). uo_out\[2\] remains HIGH (no drug).

7. Next clock cycle (clear ui_in). The FSM transitions to WALK_AWAY. uo_out\[3\] through uo_out\[6\] go HIGH. uo_out\[2\] stays HIGH.

8. Next clock cycle. The FSM returns to RANDOM_WALK again.

9. Apply reset again (rst_n = 0, then 1) to reload the drug. Now set ui_in\[1\] = 1 to test the clot_nearby path. The FSM enters WALK_AWAY directly. uo_out\[3\] through uo_out\[6\] go HIGH. uo_out\[2\] stays LOW because the drug is still loaded. No release command, no clot TX.

10. Next clock cycle (clear ui_in). The FSM returns to RANDOM_WALK. All outputs return to 0.


StepActionui_in[1:0]Stateuo_out[6:0]What happen1Reset00RANDOM_WALK0000000Robot wake up, drug loaded2Idle00RANDOM_WALK0000000Robot wander, nothing happen3Clot + drug01RELEASE_DRUG0000011Drug go out, TX clot signal4Auto00WALK_AWAY1111100Motors on, drug gone forever5Auto00RANDOM_WALK0000100Back to wander, no drug flag stay6Clot, no drug01CLOT_NO_DRUG0000110TX clot, but no drug to give7Auto00WALK_AWAY1111100Motors on again8Auto00RANDOM_WALK0000100Wander again9Reset + nearby10WALK_AWAY1111000Drug reloaded, dodge neighbor clot10Auto00RANDOM_WALK0000000All quiet, drug still loaded

## External hardware

No external hardware used in project
