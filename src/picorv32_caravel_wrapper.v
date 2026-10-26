// ==============================================================================
// Efabless Caravel SoC Harness Integration Wrapper for PicoRV32
// Target Process: SkyWater 130nm (sky130_fd_sc_hd)
// Compatible with Caravel / ChipIgnite user_project_wrapper / user_proj_example
// ==============================================================================

`default_nettype none

module picorv32_caravel_wrapper #(
    parameter BITS = 32,
    parameter MEM_WORDS = 1024 // 4 KB internal scratchpad for Caravel user area
)(
`ifdef USE_POWER_PINS
    inout vccd1, // User area 1 1.8V supply
    inout vssd1, // User area 1 Ground
`endif

    // Wishbone Slave ports (WB MI A) - Caravel Management SoC interface
    input wire          wb_clk_i,
    input wire          wb_rst_i,
    input wire          wbs_stb_i,
    input wire          wbs_cyc_i,
    input wire          wbs_we_i,
    input wire  [3:0]   wbs_sel_i,
    input wire  [31:0]  wbs_dat_i,
    input wire  [31:0]  wbs_adr_i,
    output wire         wbs_ack_o,
    output wire [31:0]  wbs_dat_o,

    // Logic Analyzer Signals
    input  wire [127:0] la_data_in,
    output wire [127:0] la_data_out,
    input  wire [127:0] la_oenb,

    // GPIO Pad Interfaces (38 dedicated IOs)
    input  wire [37:0]  io_in,
    output wire [37:0]  io_out,
    output wire [37:0]  io_oeb,

    // User Interrupts to Caravel Management Core
    output wire [2:0]   user_irq
);

    // -------------------------------------------------------------------------
    // 1. Clock & Reset Management
    // -------------------------------------------------------------------------
    wire clk = wb_clk_i;
    // Allow reset from either Wishbone bus or Logic Analyzer channel 0
    wire rst = wb_rst_i | (la_oenb[0] == 1'b0 ? la_data_in[0] : 1'b0);
    wire resetn = ~rst;

    // -------------------------------------------------------------------------
    // 2. PicoRV32 Core Signals
    // -------------------------------------------------------------------------
    wire        trap;
    wire        mem_valid;
    wire        mem_instr;
    reg         mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [ 3:0] mem_wstrb;
    reg  [31:0] mem_rdata;

    // -------------------------------------------------------------------------
    // 3. Peripheral & Memory Map
    //    0x0000_0000 - 0x0000_0FFF : 4 KB On-chip SRAM (1024 x 32-bit words)
    //    0x1000_0000               : Status register (1=PASS, 2=FAIL)
    //    0x2000_0000               : GPIO Output Data register
    //    0x2000_0004               : GPIO Input Data register
    //    0x3000_0000               : Wishbone Host Mailbox
    // -------------------------------------------------------------------------
    reg [31:0] sram [0:MEM_WORDS-1];
    reg [31:0] status_reg;
    reg [31:0] gpio_out_reg;

    // Connect GPIO pads
    assign io_out = {6'b0, gpio_out_reg};
    assign io_oeb = 38'b0; // All configured as active outputs

    // -------------------------------------------------------------------------
    // 4. Memory Bus Handshaking (1-cycle access)
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!resetn) begin
            mem_ready    <= 1'b0;
            status_reg   <= 32'd0;
            gpio_out_reg <= 32'd0;
            mem_rdata    <= 32'd0;
        end else begin
            mem_ready <= 1'b0;
            if (mem_valid && !mem_ready) begin
                mem_ready <= 1'b1;

                // SRAM Read/Write
                if (mem_addr < (MEM_WORDS * 4)) begin
                    if (|mem_wstrb) begin
                        if (mem_wstrb[0]) sram[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
                        if (mem_wstrb[1]) sram[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
                        if (mem_wstrb[2]) sram[mem_addr >> 2][23:16] <= mem_wdata[23:16];
                        if (mem_wstrb[3]) sram[mem_addr >> 2][31:24] <= mem_wdata[31:24];
                    end else begin
                        mem_rdata <= sram[mem_addr >> 2];
                    end
                end
                // Status Register
                else if (mem_addr == 32'h1000_0000) begin
                    if (|mem_wstrb)
                        status_reg <= mem_wdata;
                    else
                        mem_rdata <= status_reg;
                end
                // GPIO Outputs
                else if (mem_addr == 32'h2000_0000) begin
                    if (|mem_wstrb)
                        gpio_out_reg <= mem_wdata;
                    else
                        mem_rdata <= gpio_out_reg;
                end
                // GPIO Inputs
                else if (mem_addr == 32'h2000_0004) begin
                    mem_rdata <= io_in[31:0];
                end
                else begin
                    mem_rdata <= 32'h0000_0013; // default nop
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // 5. Wishbone Slave Bridge (Caravel SoC Access)
    // -------------------------------------------------------------------------
    reg wb_ack;
    reg [31:0] wb_rdata;
    wire wb_valid = wbs_cyc_i && wbs_stb_i;

    always @(posedge clk) begin
        if (rst) begin
            wb_ack   <= 1'b0;
            wb_rdata <= 32'd0;
        end else begin
            wb_ack <= 1'b0;
            if (wb_valid && !wb_ack) begin
                wb_ack <= 1'b1;
                // Read PicoRV32 status from Wishbone
                if (wbs_adr_i[7:0] == 8'h00) begin
                    wb_rdata <= status_reg;
                end else if (wbs_adr_i[7:0] == 8'h04) begin
                    wb_rdata <= {31'b0, trap};
                end else if (wbs_adr_i[7:0] == 8'h08) begin
                    wb_rdata <= mem_addr;
                end else begin
                    wb_rdata <= 32'hDEAD_BEEF;
                end
            end
        end
    end

    assign wbs_ack_o = wb_ack;
    assign wbs_dat_o = wb_rdata;

    // -------------------------------------------------------------------------
    // 6. Logic Analyzer Monitoring Probes
    // -------------------------------------------------------------------------
    assign la_data_out[31:0]   = mem_addr;
    assign la_data_out[63:32]  = mem_wdata;
    assign la_data_out[64]     = trap;
    assign la_data_out[65]     = mem_valid;
    assign la_data_out[66]     = mem_ready;
    assign la_data_out[98:67]  = status_reg;
    assign la_data_out[127:99] = 29'b0;

    // -------------------------------------------------------------------------
    // 7. Interrupt Outputs
    // -------------------------------------------------------------------------
    assign user_irq[0] = trap;
    assign user_irq[1] = (status_reg == 32'd1); // PASS interrupt
    assign user_irq[2] = (status_reg == 32'd2); // FAIL interrupt

    // -------------------------------------------------------------------------
    // 8. Core CPU Instantiation
    // -------------------------------------------------------------------------
`ifdef GLS
    picorv32 core (
        .VPWR(vccd1),
        .VGND(vssd1),
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
    picorv32 core (
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

endmodule

`default_nettype wire
