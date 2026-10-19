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

    // 64 KB Memory
    reg [31:0] memory [0:16383];
    integer i;

    // Clock generator: 133.33 MHz (7.5 ns period -> 3.75 ns half period)
    initial clk = 0;
    always #3.75 clk = ~clk;

    // Instantiate PicoRV32 Core
    picorv32 #(
        .ENABLE_COUNTERS(1),
        .ENABLE_COUNTERS64(0),
        .ENABLE_REGS_16_31(1),
        .ENABLE_REGS_DUALPORT(1),
        .TWO_STAGE_SHIFT(1),
        .BARREL_SHIFTER(0),
        .TWO_CYCLE_COMPARE(0),
        .TWO_CYCLE_ALU(0),
        .COMPRESSED_ISA(0),
        .CATCH_MISALIGN(1),
        .CATCH_ILLINSN(1)
    ) uut (
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
        // Look-ahead interface (unused)
        .mem_la_read(),
        .mem_la_write(),
        .mem_la_addr(),
        .mem_la_wdata(),
        .mem_la_wstrb(),
        // PCPI (unused)
        .pcpi_valid(),
        .pcpi_insn(),
        .pcpi_rs1(),
        .pcpi_rs2(),
        .pcpi_wr(1'b0),
        .pcpi_rd(32'd0),
        .pcpi_wait(1'b0),
        .pcpi_ready(1'b0),
        // IRQ
        .irq(32'd0)
    );

    // Memory Bus Logic
    always @(posedge clk) begin
        if (!resetn) begin
            mem_ready <= 0;
        end else begin
            mem_ready <= 0;
            if (mem_valid && !mem_ready) begin
                mem_ready <= 1;
                // Handle read
                if (mem_wstrb == 4'b0000) begin
                    mem_rdata <= memory[mem_addr >> 2];
                end
                // Handle write
                else begin
                    if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
                    if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
                    if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
                    if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];

                    // Check for Status Register Write at 0x1000_0000
                    if (mem_addr == 32'h1000_0000) begin
                        if (mem_wdata == 32'h0000_0001) begin
                            $display("\n============================================================");
                            $display(" [SIMULATION SUCCESS] RISC-V PicoRV32 Verification PASSED!");
                            $display(" - Arithmetic (ADD/SUB/ADDI): PASS");
                            $display(" - Memory Access (SW/LW):     PASS");
                            $display(" - Branching Loop (BNE/JAL):  PASS (Sum 1..5 = 15 Verified)");
                            $display(" - Total Cycles Executed:     %0d cycles", $time / 7.5);
                            $display("============================================================\n");
                            $finish;
                        end else if (mem_wdata == 32'h0000_0002) begin
                            $display("\n[SIMULATION ERROR] Assertion failed in firmware execution!");
                            $finish;
                        end
                    end
                end
            end
        end
    end

    // Test stimulus and firmware loading
    initial begin
        $display("Starting PicoRV32 Testbench Simulation...");
        // Initialize memory with NOPs
        for (i = 0; i < 16384; i = i + 1)
            memory[i] = 32'h00000013; // nop (addi x0, x0, 0)

        // Embedded firmware program (RV32I machine code)
        memory[0]  = 32'h00a00093; // addi x1, x0, 10
        memory[1]  = 32'h01400113; // addi x2, x0, 20
        memory[2]  = 32'h002081b3; // add  x3, x1, x2  (x3 = 30)
        memory[3]  = 32'h04302023; // sw   x3, 64(x0)  (save 30 to mem[16])
        memory[4]  = 32'h04002203; // lw   x4, 64(x0)  (load from mem[16])
        memory[5]  = 32'h403202b3; // sub  x5, x4, x3  (x5 = 30 - 30 = 0)
        memory[6]  = 32'h02029863; // bne  x5, x0, FAIL (to word 18)
        memory[7]  = 32'h00500313; // addi x6, x0, 5   (counter = 5)
        memory[8]  = 32'h00000393; // addi x7, x0, 0   (sum = 0)
        // Loop: word 9 (addr 0x24)
        memory[9]  = 32'h006383b3; // add  x7, x7, x6  (sum += counter)
        memory[10] = 32'hfff30313; // addi x6, x6, -1  (counter--)
        memory[11] = 32'hfe031ee3; // bne  x6, x0, -8  (branch to Loop)
        memory[12] = 32'h00f00413; // addi x8, x0, 15  (expected sum = 15)
        memory[13] = 32'h00839863; // bne  x7, x8, FAIL (to word 18)
        memory[14] = 32'h100004b7; // lui  x9, 0x10000 (status port 0x1000_0000)
        memory[15] = 32'h00100513; // addi x10, x0, 1  (PASS code = 1)
        memory[16] = 32'h00a4a023; // sw   x10, 0(x9)  (Write PASS token)
        memory[17] = 32'h0000006f; // jal  x0, 0       (Halt)
        // FAIL handler: word 18
        memory[18] = 32'h100004b7; // lui  x9, 0x10000
        memory[19] = 32'h00200513; // addi x10, x0, 2  (FAIL code = 2)
        memory[20] = 32'h00a4a023; // sw   x10, 0(x9)  (Write FAIL token)
        memory[21] = 32'h0000006f; // jal  x0, 0       (Halt)

        // Reset sequence
        resetn = 0;
        #50;
        @(posedge clk);
        resetn = 1;
        $display("Reset released. CPU executing from address 0x0000_0000...");

        // Watchdog timeout (10,000 cycles)
        #75000;
        $display("\n[SIMULATION TIMEOUT] CPU did not signal completion within 10,000 cycles!");
        $finish;
    end

endmodule
