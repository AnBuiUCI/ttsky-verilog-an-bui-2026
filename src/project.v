/*
 * Copyright (c) 2026 An Bui
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_main_fsm_anbui_uci (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // Inputs
    wire clot_detected = ui_in[0];  // local sensor input
    wire clot_nearby   = ui_in[1];  // RX signal from another robot

    // States
    localparam RANDOM_WALK  = 2'd0;
    localparam RELEASE_DRUG = 2'd1;
    localparam CLOT_NO_DRUG = 2'd2;
    localparam WALK_AWAY    = 2'd3;

    reg [1:0] state;
    reg [1:0] next_state;

    // Internal memory: starts with drug after reset
    reg contains_drug;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= RANDOM_WALK;
            contains_drug <= 1'b1;
        end else begin
            state <= next_state;

            if (state == RELEASE_DRUG)
                contains_drug <= 1'b0;
        end
    end

    always @(*) begin
        next_state = state;

        case (state)

            RANDOM_WALK: begin
                if (clot_detected && contains_drug)
                    next_state = RELEASE_DRUG;
                else if (clot_detected && !contains_drug)
                    next_state = CLOT_NO_DRUG;
                else if (clot_nearby)
                    next_state = WALK_AWAY;
                else
                    next_state = RANDOM_WALK;
            end

            RELEASE_DRUG: begin
                next_state = WALK_AWAY;
            end

            CLOT_NO_DRUG: begin
                next_state = WALK_AWAY;
            end

            WALK_AWAY: begin
                next_state = RANDOM_WALK;
            end

            default: begin
                next_state = RANDOM_WALK;
            end

        endcase
    end

    // Output mapping
    assign uo_out[0] = (state == RELEASE_DRUG);  // release_drug_cmd

    assign uo_out[1] = (state == RELEASE_DRUG) ||
                       (state == CLOT_NO_DRUG);  // clot_detected_out TX

    assign uo_out[2] = !contains_drug;           // no_drug_out TX

    assign uo_out[3] = (state == WALK_AWAY);     // motor1_on
    assign uo_out[4] = (state == WALK_AWAY);     // motor2_on
    assign uo_out[5] = (state == WALK_AWAY);     // motor3_on
    assign uo_out[6] = (state == WALK_AWAY);     // motor4_on

    assign uo_out[7] = 1'b0;

    // Unused bidirectional IOs
    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;

    // Prevent unused input warnings
    wire _unused = &{ena, uio_in, ui_in[7:2], 1'b0};

endmodule
