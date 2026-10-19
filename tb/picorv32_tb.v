`timescale 1 ns / 1 ps

module picorv32_tb;

    reg clk;
    reg resetn;
    wire trap;

    wire        mem_valid;
    wire        mem_instr;
    reg         mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [ 3:0] mem_wstrb;
    reg  [31:0] mem_rdata;

    // 64 KB Memory model
    reg [31:0] memory [0:16383];
    integer i;

    // Clock generator: 133.33 MHz (7.5 ns period -> 3.75 ns half-cycle)
    initial clk = 0;
    always #3.75 clk = ~clk;

    // Instantiate PicoRV32 (supports both RTL and post-PnR gate-level netlist)
`ifdef GLS
    wire VPWR = 1'b1;
    wire VGND = 1'b0;
    picorv32 uut (
        .VPWR(VPWR),
        .VGND(VGND),
        .clk(clk),
        .resetn(resetn),
        .trap(trap),
        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),
        .mem_la_read(),
        .mem_la_write(),
        .mem_la_addr(),
        .mem_la_wdata(),
        .mem_la_wstrb(),
        .pcpi_valid(),
        .pcpi_insn(),
        .pcpi_rs1(),
        .pcpi_rs2(),
        .pcpi_wr(1'b0),
        .pcpi_rd(32'd0),
        .pcpi_wait(1'b0),
        .pcpi_ready(1'b0),
        .irq(32'd0)
    );
`else
    picorv32 uut (
        .clk(clk),
        .resetn(resetn),
        .trap(trap),
        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),
        .mem_la_read(),
        .mem_la_write(),
        .mem_la_addr(),
        .mem_la_wdata(),
        .mem_la_wstrb(),
        .pcpi_valid(),
        .pcpi_insn(),
        .pcpi_rs1(),
        .pcpi_rs2(),
        .pcpi_wr(1'b0),
        .pcpi_rd(32'd0),
        .pcpi_wait(1'b0),
        .pcpi_ready(1'b0),
        .irq(32'd0)
    );
`endif

    // Memory Bus Protocol
    always @(posedge clk) begin
        if (!resetn) begin
            mem_ready <= 0;
        end else begin
            mem_ready <= 0;
            if (mem_valid && !mem_ready) begin
                mem_ready <= 1;
                // Read
                if (mem_wstrb == 4'b0000) begin
                    if ((mem_addr >> 2) < 16384)
                        mem_rdata <= memory[mem_addr >> 2];
                    else
                        mem_rdata <= 32'h00000013; // default nop
                end
                // Write
                else begin
                    if ((mem_addr >> 2) < 16384) begin
                        if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
                        if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
                        if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
                        if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
                    end

                    // Check Status Register at 0x1000_0000
                    if (mem_addr == 32'h1000_0000) begin
                        if (mem_wdata == 32'h0000_0001) begin
                            $display("\n============================================================");
                            $display(" [SIMULATION SUCCESS] RISC-V PicoRV32 Verification PASSED!");
                            $display(" - Arithmetic: ADDI, ADD, SUB           -> PASS");
                            $display(" - Bitwise Logic: AND, OR, XOR          -> PASS");
                            $display(" - Shift / Compare: SLLI, SRLI, SLT     -> PASS");
                            $display(" - Memory Access: SW, LW, BEQ           -> PASS");
                            $display(" - Iterative Summation Loop: BNE, JAL   -> PASS (Sum 1..5 = 15)");
                            $display(" - Total Elapsed Time: %0.2f ns (~%0d clock cycles)", $realtime, $realtime / 7.5);
                            $display("============================================================\n");
                            $finish;
                        end else if (mem_wdata == 32'h0000_0002) begin
                            $display("\n[SIMULATION FAILED] Assertion failure at step!");
                            $finish;
                        end
                    end
                end
            end
        end
    end

    // Test sequence initialization
    initial begin
        $display("Starting PicoRV32 Comprehensive Verification Suite...");
        for (i = 0; i < 16384; i = i + 1)
            memory[i] = 32'h00000013; // nop (addi x0, x0, 0)

        // 1. Arithmetic
        memory[0]  = 32'h00a00093; // 0x00: addi x1, x0, 10
        memory[1]  = 32'h01400113; // 0x04: addi x2, x0, 20
        memory[2]  = 32'h002081b3; // 0x08: add  x3, x1, x2 (x3 = 30)
        memory[3]  = 32'h40118233; // 0x0c: sub  x4, x3, x1 (x4 = 20)
        memory[4]  = 32'h08221463; // 0x10: bne  x4, x2, FAIL
        // 2. Bitwise Logic
        memory[5]  = 32'h00f00293; // 0x14: addi x5, x0, 15 (0x0F)
        memory[6]  = 32'h03300313; // 0x18: addi x6, x0, 51 (0x33)
        memory[7]  = 32'h0062f3b3; // 0x1c: and  x7, x5, x6 (x7 = 3)
        memory[8]  = 32'h00300413; // 0x20: addi x8, x0, 3
        memory[9]  = 32'h06839a63; // 0x24: bne  x7, x8, FAIL
        memory[10] = 32'h0062e4b3; // 0x28: or   x9, x5, x6 (x9 = 63)
        memory[11] = 32'h03f00513; // 0x2c: addi x10, x0, 63
        memory[12] = 32'h06a49463; // 0x30: bne  x9, x10, FAIL
        memory[13] = 32'h0062c5b3; // 0x34: xor  x11, x5, x6 (x11 = 60)
        memory[14] = 32'h03c00613; // 0x38: addi x12, x0, 60
        memory[15] = 32'h04c59e63; // 0x3c: bne  x11, x12, FAIL
        // 3. Shifts & Comparison
        memory[16] = 32'h00229693; // 0x40: slli x13, x5, 2 (15 << 2 = 60)
        memory[17] = 32'h04c69a63; // 0x44: bne  x13, x12, FAIL
        memory[18] = 32'h0026d713; // 0x48: srli x14, x13, 2 (60 >> 2 = 15)
        memory[19] = 32'h04571663; // 0x4c: bne  x14, x5, FAIL
        memory[20] = 32'h0020a7b3; // 0x50: slt  x15, x1, x2 (10 < 20 -> 1)
        memory[21] = 32'h00100813; // 0x54: addi x16, x0, 1
        memory[22] = 32'h05079063; // 0x58: bne  x15, x16, FAIL
        // 4. Memory Access & Branching
        memory[23] = 32'h04302023; // 0x5c: sw   x3, 64(x0) (store 30)
        memory[24] = 32'h04002883; // 0x60: lw   x17, 64(x0) (load 30)
        memory[25] = 32'h00388463; // 0x64: beq  x17, x3, MEM_OK
        memory[26] = 32'h0300006f; // 0x68: j FAIL
        // 5. Iterative Summation Loop
        memory[27] = 32'h00500913; // 0x6c: addi x18, x0, 5 (counter)
        memory[28] = 32'h00000993; // 0x70: addi x19, x0, 0 (sum)
        memory[29] = 32'h012989b3; // 0x74: add  x19, x19, x18
        memory[30] = 32'hfff90913; // 0x78: addi x18, x18, -1
        memory[31] = 32'hfe091ce3; // 0x7c: bne  x18, x0, LOOP
        memory[32] = 32'h00f00a13; // 0x80: addi x20, x0, 15
        memory[33] = 32'h01499a63; // 0x84: bne  x19, x20, FAIL
        // SUCCESS Handler
        memory[34] = 32'h10000ab7; // 0x88: lui  x21, 0x10000
        memory[35] = 32'h00100b13; // 0x8c: addi x22, x0, 1
        memory[36] = 32'h016aa023; // 0x90: sw   x22, 0(x21) -> Status PASS (1)
        memory[37] = 32'h0000006f; // 0x94: j HALT
        // FAIL Handler
        memory[38] = 32'h10000ab7; // 0x98: lui  x21, 0x10000
        memory[39] = 32'h00200b13; // 0x9c: addi x22, x0, 2
        memory[40] = 32'h016aa023; // 0xa0: sw   x22, 0(x21) -> Status FAIL (2)
        memory[41] = 32'h0000006f; // 0xa4: j FAIL_HALT

        // Reset Sequence
        resetn = 0;
        repeat (20) @(posedge clk);
        resetn = 1;
        $display("Reset released. Executing RV32I verification sequence...");

        // Watchdog timeout (15,000 cycles)
        #112500;
        $display("\n[SIMULATION TIMEOUT] CPU did not signal completion within watchdog window!");
        $finish;
    end

endmodule
