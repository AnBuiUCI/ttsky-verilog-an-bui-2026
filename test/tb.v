`default_nettype none
`timescale 1ns / 1ps

module tb_tt_um_main_fsm;

    reg  [7:0] ui_in;
    wire [7:0] uo_out;
    reg  [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;
    reg        ena;
    reg        clk;
    reg        rst_n;

    // DUT
    tt_um_main_fsm_anbui_uci dut (
        .ui_in   (ui_in),
        .uo_out  (uo_out),
        .uio_in  (uio_in),
        .uio_out (uio_out),
        .uio_oe  (uio_oe),
        .ena     (ena),
        .clk     (clk),
        .rst_n   (rst_n)
    );

    // Clock: 10ns period
    always #5 clk = ~clk;

    // Helper wires for readability
    wire release_drug_cmd  = uo_out[0];
    wire clot_detected_out = uo_out[1];
    wire no_drug_out       = uo_out[2];
    wire motor1_on         = uo_out[3];
    wire motor2_on         = uo_out[4];
    wire motor3_on         = uo_out[5];
    wire motor4_on         = uo_out[6];

    integer pass_count = 0;
    integer fail_count = 0;

    task check(
        input [7:0] expected_out,
        input [63:0] test_name // 8-char label padded
    );
        begin
            if (uo_out !== expected_out) begin
                $display("FAIL [%0s] time=%0t: uo_out=%b, expected=%b",
                         test_name, $time, uo_out, expected_out);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS [%0s] time=%0t: uo_out=%b",
                         test_name, $time, uo_out);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_tt_um_main_fsm.vcd");
        $dumpvars(0, tb_tt_um_main_fsm);

        // Init
        clk   = 0;
        rst_n = 0;
        ena   = 1;
        ui_in = 8'b0;
        uio_in = 8'b0;

        // =============================================
        // TEST 1: Reset behavior
        // After reset: state=RANDOM_WALK, contains_drug=1
        // Expected uo_out: all 0 (wandering, no action)
        // =============================================
        #20;
        rst_n = 1;
        @(posedge clk); #1;
        check(8'b0000_0000, "RESET   ");

        // =============================================
        // TEST 2: RANDOM_WALK with no inputs
        // Should stay in RANDOM_WALK, outputs all 0
        // =============================================
        ui_in = 8'b0;
        @(posedge clk); #1;
        check(8'b0000_0000, "IDLE    ");

        // =============================================
        // TEST 3: Clot detected + has drug -> RELEASE_DRUG
        // uo_out[0]=1 (release), uo_out[1]=1 (TX clot),
        // uo_out[2]=0 (still has drug this cycle)
        // motors off
        // =============================================
        ui_in[0] = 1; // clot_detected
        @(posedge clk); #1;
        check(8'b0000_0011, "REL_DRUG");

        // =============================================
        // TEST 4: After RELEASE_DRUG -> WALK_AWAY
        // Motors on (bits 6:3), no_drug_out=1 (bit 2)
        // release_drug_cmd=0, clot_detected_out=0
        // =============================================
        ui_in = 8'b0; // clear inputs
        @(posedge clk); #1;
        check(8'b0111_1100, "WALKAWAY");

        // =============================================
        // TEST 5: After WALK_AWAY -> back to RANDOM_WALK
        // Drug is now gone, so no_drug_out=1 (bit 2)
        // =============================================
        @(posedge clk); #1;
        check(8'b0000_0100, "BACK_RW ");

        // =============================================
        // TEST 6: Clot detected + NO drug -> CLOT_NO_DRUG
        // uo_out[1]=1 (TX clot), uo_out[2]=1 (no drug)
        // uo_out[0]=0 (no release)
        // =============================================
        ui_in[0] = 1; // clot_detected
        @(posedge clk); #1;
        check(8'b0000_0110, "NO_DRUG ");

        // =============================================
        // TEST 7: CLOT_NO_DRUG -> WALK_AWAY
        // Motors on + no_drug_out
        // =============================================
        ui_in = 8'b0;
        @(posedge clk); #1;
        check(8'b0111_1100, "WALKAW2 ");

        // =============================================
        // TEST 8: WALK_AWAY -> RANDOM_WALK again
        // =============================================
        @(posedge clk); #1;
        check(8'b0000_0100, "BACK_RW2");

        // =============================================
        // TEST 9: Reset again, test clot_nearby path
        // clot_nearby (bit 1) -> WALK_AWAY from RANDOM_WALK
        // =============================================
        rst_n = 0;
        #20;
        rst_n = 1;
        @(posedge clk); #1;

        ui_in = 8'b0000_0010; // clot_nearby = 1
        @(posedge clk); #1;
        check(8'b0111_1000, "NEARBY  ");
        // contains_drug still 1, so no_drug_out=0

        // =============================================
        // TEST 10: Back to RANDOM_WALK after nearby dodge
        // =============================================
        ui_in = 8'b0;
        @(posedge clk); #1;
        check(8'b0000_0000, "DODGE_RW");

        // =============================================
        // TEST 11: Priority check
        // clot_detected=1 AND clot_nearby=1, has drug
        // clot_detected should win -> RELEASE_DRUG
        // =============================================
        ui_in = 8'b0000_0011; // both bits set
        @(posedge clk); #1;
        check(8'b0000_0011, "PRIORITY");

        // =============================================
        // TEST 12: Verify uio outputs tied off
        // =============================================
        if (uio_out !== 8'b0 || uio_oe !== 8'b0) begin
            $display("FAIL [UIO_TIE] uio_out=%b uio_oe=%b", uio_out, uio_oe);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS [UIO_TIE] bidirectional IOs properly tied off");
            pass_count = pass_count + 1;
        end

        // =============================================
        // Summary
        // =============================================
        #10;
        $display("");
        $display("========================================");
        $display("  RESULTS: %0d passed, %0d failed", pass_count, fail_count);
        $display("========================================");
        $finish;
    end

endmodule
