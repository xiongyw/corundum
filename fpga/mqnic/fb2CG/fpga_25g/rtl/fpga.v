// SPDX-License-Identifier: BSD-2-Clause-Views
/*
 * Copyright (c) 2019-2023 The Regents of the University of California
 */

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * FPGA top-level module
 */
module fpga #
(
    // FW and board IDs
    parameter FPGA_ID = 32'h4A56093,
    parameter FW_ID = 32'h00000000,
    parameter FW_VER = 32'h00_00_01_00,
    parameter BOARD_ID = 32'h1c2c_a00e,
    parameter BOARD_VER = 32'h01_00_00_00,
    parameter BUILD_DATE = 32'd602976000,
    parameter GIT_HASH = 32'hdce357bf,
    parameter RELEASE_INFO = 32'h00000000,

    // Board configuration
    parameter TDMA_BER_ENABLE = 0,

    // Structural configuration
    parameter IF_COUNT = 2,
    parameter PORTS_PER_IF = 1,
    parameter SCHED_PER_IF = PORTS_PER_IF,
    parameter PORT_MASK = 0,

    // Clock configuration
    parameter CLK_PERIOD_NS_NUM = 4,
    parameter CLK_PERIOD_NS_DENOM = 1,

    // PTP configuration
    parameter PTP_CLOCK_PIPELINE = 0,
    parameter PTP_CLOCK_CDC_PIPELINE = 0,
    parameter PTP_PORT_CDC_PIPELINE = 0,
    parameter PTP_PEROUT_ENABLE = 1,
    parameter PTP_PEROUT_COUNT = 1,

    // Queue manager configuration
    parameter EVENT_QUEUE_OP_TABLE_SIZE = 32,
    parameter TX_QUEUE_OP_TABLE_SIZE = 32,
    parameter RX_QUEUE_OP_TABLE_SIZE = 32,
    parameter CQ_OP_TABLE_SIZE = 32,
    parameter EQN_WIDTH = 5,
    parameter TX_QUEUE_INDEX_WIDTH = 13,
    parameter RX_QUEUE_INDEX_WIDTH = 8,
    parameter CQN_WIDTH = (TX_QUEUE_INDEX_WIDTH > RX_QUEUE_INDEX_WIDTH ? TX_QUEUE_INDEX_WIDTH : RX_QUEUE_INDEX_WIDTH) + 1,
    parameter EQ_PIPELINE = 3,
    parameter TX_QUEUE_PIPELINE = 3+(TX_QUEUE_INDEX_WIDTH > 12 ? TX_QUEUE_INDEX_WIDTH-12 : 0),
    parameter RX_QUEUE_PIPELINE = 3+(RX_QUEUE_INDEX_WIDTH > 12 ? RX_QUEUE_INDEX_WIDTH-12 : 0),
    parameter CQ_PIPELINE = 3+(CQN_WIDTH > 12 ? CQN_WIDTH-12 : 0),

    // TX and RX engine configuration
    parameter TX_DESC_TABLE_SIZE = 32,
    parameter RX_DESC_TABLE_SIZE = 32,
    parameter RX_INDIR_TBL_ADDR_WIDTH = RX_QUEUE_INDEX_WIDTH > 8 ? 8 : RX_QUEUE_INDEX_WIDTH,

    // Scheduler configuration
    parameter TX_SCHEDULER_OP_TABLE_SIZE = TX_DESC_TABLE_SIZE,
    parameter TX_SCHEDULER_PIPELINE = TX_QUEUE_PIPELINE,
    parameter TDMA_INDEX_WIDTH = 6,

    // Interface configuration
    parameter PTP_TS_ENABLE = 1,
    parameter TX_CPL_FIFO_DEPTH = 32,
    parameter TX_CHECKSUM_ENABLE = 1,
    parameter RX_HASH_ENABLE = 1,
    parameter RX_CHECKSUM_ENABLE = 1,
    parameter PFC_ENABLE = 1,
    parameter LFC_ENABLE = PFC_ENABLE,
    parameter ENABLE_PADDING = 1,
    parameter ENABLE_DIC = 1,
    parameter MIN_FRAME_LENGTH = 64,
    parameter TX_FIFO_DEPTH = 32768,
    parameter RX_FIFO_DEPTH = 32768,
    parameter MAX_TX_SIZE = 9214,
    parameter MAX_RX_SIZE = 9214,
    parameter TX_RAM_SIZE = 32768,
    parameter RX_RAM_SIZE = 32768,

    // RAM configuration
    parameter DDR_CH = 4,
    parameter DDR_ENABLE = 0,
    parameter AXI_DDR_DATA_WIDTH = 512,
    parameter AXI_DDR_ADDR_WIDTH = 32,
    parameter AXI_DDR_ID_WIDTH = 8,
    parameter AXI_DDR_MAX_BURST_LEN = 256,
    parameter AXI_DDR_NARROW_BURST = 0,

    // Application block configuration
    parameter APP_ID = 32'h00000000,
    parameter APP_ENABLE = 0,
    parameter APP_CTRL_ENABLE = 1,
    parameter APP_DMA_ENABLE = 1,
    parameter APP_AXIS_DIRECT_ENABLE = 1,
    parameter APP_AXIS_SYNC_ENABLE = 1,
    parameter APP_AXIS_IF_ENABLE = 1,
    parameter APP_STAT_ENABLE = 1,

    // DMA interface configuration
    parameter DMA_IMM_ENABLE = 0,
    parameter DMA_IMM_WIDTH = 32,
    parameter DMA_LEN_WIDTH = 16,
    parameter DMA_TAG_WIDTH = 16,
    parameter RAM_ADDR_WIDTH = $clog2(TX_RAM_SIZE > RX_RAM_SIZE ? TX_RAM_SIZE : RX_RAM_SIZE),
    parameter RAM_PIPELINE = 2,

    // PCIe interface configuration
    parameter AXIS_PCIE_DATA_WIDTH = 512,
    parameter PF_COUNT = 1,
    parameter VF_COUNT = 0,

    // Interrupt configuration
    parameter IRQ_INDEX_WIDTH = EQN_WIDTH,

    // AXI lite interface configuration (control)
    parameter AXIL_CTRL_DATA_WIDTH = 32,
    parameter AXIL_CTRL_ADDR_WIDTH = 24,

    // AXI lite interface configuration (application control)
    parameter AXIL_APP_CTRL_DATA_WIDTH = AXIL_CTRL_DATA_WIDTH,
    parameter AXIL_APP_CTRL_ADDR_WIDTH = 24,

    // Ethernet interface configuration
    parameter AXIS_ETH_SYNC_DATA_WIDTH_DOUBLE = 1,
    parameter AXIS_ETH_TX_PIPELINE = 0,
    parameter AXIS_ETH_TX_FIFO_PIPELINE = 2,
    parameter AXIS_ETH_TX_TS_PIPELINE = 0,
    parameter AXIS_ETH_RX_PIPELINE = 0,
    parameter AXIS_ETH_RX_FIFO_PIPELINE = 2,

    // Statistics counter subsystem
    parameter STAT_ENABLE = 1,
    parameter STAT_DMA_ENABLE = 1,
    parameter STAT_PCIE_ENABLE = 1,
    parameter STAT_INC_WIDTH = 24,
    parameter STAT_ID_WIDTH = 12
)
(
    /*
     * Clock: 100MHz
     */
    input  wire         init_clk,
    input  wire         clk_ddr4_refclk1_p,
    input  wire         clk_ddr4_refclk1_n,
    input  wire         clk_ddr4_refclk2_p,
    input  wire         clk_ddr4_refclk2_n,

    /*
     * GPIO
     */
    output wire         led_sreg_d,
    output wire         led_sreg_ld,
    output wire         led_sreg_clk,
    output wire [1:0]   led_bmc,
    output wire [1:0]   led_exp,

    input  wire         pps_in,
    output wire         pps_out,
    output wire         pps_out_en,

    /*
     * BMC interface
     */
    output wire         bmc_clk,
    output wire         bmc_nss,
    output wire         bmc_mosi,
    input  wire         bmc_miso,
    input  wire         bmc_int,

    /*
     * Board status
     */
    input  wire [1:0]   pg,

    /*
     * PCI express
     */
    input  wire [15:0]  pcie_rx_p,
    input  wire [15:0]  pcie_rx_n,
    output wire [15:0]  pcie_tx_p,
    output wire [15:0]  pcie_tx_n,
    input  wire         pcie_refclk_p,
    input  wire         pcie_refclk_n,
    input  wire         pcie_rst_n,

    /*
     * Ethernet: QSFP28
     */
    output wire [3:0]   qsfp_0_tx_p,
    output wire [3:0]   qsfp_0_tx_n,
    input  wire [3:0]   qsfp_0_rx_p,
    input  wire [3:0]   qsfp_0_rx_n,
    input  wire         qsfp_0_mgt_refclk_p,
    input  wire         qsfp_0_mgt_refclk_n,
    input  wire         qsfp_0_mod_prsnt_n,
    output wire         qsfp_0_reset_n,
    output wire         qsfp_0_lp_mode,
    input  wire         qsfp_0_intr_n,
    inout  wire         qsfp_0_i2c_scl,
    inout  wire         qsfp_0_i2c_sda,


    output wire [3:0]   qsfp_1_tx_p,
    output wire [3:0]   qsfp_1_tx_n,
    input  wire [3:0]   qsfp_1_rx_p,
    input  wire [3:0]   qsfp_1_rx_n,
    input  wire         qsfp_1_mgt_refclk_p,
    input  wire         qsfp_1_mgt_refclk_n,
    input  wire         qsfp_1_mod_prsnt_n,
    output wire         qsfp_1_reset_n,
    output wire         qsfp_1_lp_mode,
    input  wire         qsfp_1_intr_n,
    inout  wire         qsfp_1_i2c_scl,
    inout  wire         qsfp_1_i2c_sda,

    /*
     * DDR4
     */
    output wire [16:0]  ddr4_c0_adr,
    output wire [1:0]   ddr4_c0_ba,
    output wire [1:0]   ddr4_c0_bg,
    output wire         ddr4_c0_ck_t,
    output wire         ddr4_c0_ck_c,
    output wire         ddr4_c0_cke,
    output wire         ddr4_c0_cs_n,
    output wire         ddr4_c0_act_n,
    output wire         ddr4_c0_odt,
    output wire         ddr4_c0_par,
    input  wire         ddr4_c0_alert_n,
    output wire         ddr4_c0_reset_n,
    output wire         ddr4_c0_ten,
    inout  wire [71:0]  ddr4_c0_dq,
    inout  wire [8:0]   ddr4_c0_dqs_t,
    inout  wire [8:0]   ddr4_c0_dqs_c,
    inout  wire [8:0]   ddr4_c0_dm_dbi_n,

    output wire [16:0]  ddr4_c1_adr,
    output wire [1:0]   ddr4_c1_ba,
    output wire [1:0]   ddr4_c1_bg,
    output wire         ddr4_c1_ck_t,
    output wire         ddr4_c1_ck_c,
    output wire         ddr4_c1_cke,
    output wire         ddr4_c1_cs_n,
    output wire         ddr4_c1_act_n,
    output wire         ddr4_c1_odt,
    output wire         ddr4_c1_par,
    input  wire         ddr4_c1_alert_n,
    output wire         ddr4_c1_reset_n,
    output wire         ddr4_c1_ten,
    inout  wire [71:0]  ddr4_c1_dq,
    inout  wire [8:0]   ddr4_c1_dqs_t,
    inout  wire [8:0]   ddr4_c1_dqs_c,
    inout  wire [8:0]   ddr4_c1_dm_dbi_n,

    output wire [16:0]  ddr4_c2_adr,
    output wire [1:0]   ddr4_c2_ba,
    output wire [1:0]   ddr4_c2_bg,
    output wire         ddr4_c2_ck_t,
    output wire         ddr4_c2_ck_c,
    output wire         ddr4_c2_cke,
    output wire         ddr4_c2_cs_n,
    output wire         ddr4_c2_act_n,
    output wire         ddr4_c2_odt,
    output wire         ddr4_c2_par,
    input  wire         ddr4_c2_alert_n,
    output wire         ddr4_c2_reset_n,
    output wire         ddr4_c2_ten,
    inout  wire [71:0]  ddr4_c2_dq,
    inout  wire [8:0]   ddr4_c2_dqs_t,
    inout  wire [8:0]   ddr4_c2_dqs_c,
    inout  wire [8:0]   ddr4_c2_dm_dbi_n,

    output wire [16:0]  ddr4_c3_adr,
    output wire [1:0]   ddr4_c3_ba,
    output wire [1:0]   ddr4_c3_bg,
    output wire         ddr4_c3_ck_t,
    output wire         ddr4_c3_ck_c,
    output wire         ddr4_c3_cke,
    output wire         ddr4_c3_cs_n,
    output wire         ddr4_c3_act_n,
    output wire         ddr4_c3_odt,
    output wire         ddr4_c3_par,
    input  wire         ddr4_c3_alert_n,
    output wire         ddr4_c3_reset_n,
    output wire         ddr4_c3_ten,
    inout  wire [71:0]  ddr4_c3_dq,
    inout  wire [8:0]   ddr4_c3_dqs_t,
    inout  wire [8:0]   ddr4_c3_dqs_c,
    inout  wire [8:0]   ddr4_c3_dm_dbi_n
);

// PTP configuration
parameter PTP_CLK_PERIOD_NS_NUM = 1024;
parameter PTP_CLK_PERIOD_NS_DENOM = 165;
parameter PTP_TS_WIDTH = 96;
parameter IF_PTP_PERIOD_NS = 6'h2;
parameter IF_PTP_PERIOD_FNS = 16'h8F5C;

// Interface configuration
parameter TX_TAG_WIDTH = 16;

// RAM configuration
parameter AXI_DDR_STRB_WIDTH = (AXI_DDR_DATA_WIDTH/8);

// PCIe interface configuration
parameter AXIS_PCIE_KEEP_WIDTH = (AXIS_PCIE_DATA_WIDTH/32);
parameter AXIS_PCIE_RC_USER_WIDTH = AXIS_PCIE_DATA_WIDTH < 512 ? 75 : 161;
parameter AXIS_PCIE_RQ_USER_WIDTH = AXIS_PCIE_DATA_WIDTH < 512 ? 62 : 137;
parameter AXIS_PCIE_CQ_USER_WIDTH = AXIS_PCIE_DATA_WIDTH < 512 ? 85 : 183;
parameter AXIS_PCIE_CC_USER_WIDTH = AXIS_PCIE_DATA_WIDTH < 512 ? 33 : 81;
parameter RC_STRADDLE = AXIS_PCIE_DATA_WIDTH >= 256;
parameter RQ_STRADDLE = AXIS_PCIE_DATA_WIDTH >= 512;
parameter CQ_STRADDLE = AXIS_PCIE_DATA_WIDTH >= 512;
parameter CC_STRADDLE = AXIS_PCIE_DATA_WIDTH >= 512;
parameter RQ_SEQ_NUM_WIDTH = 6;
parameter PCIE_TAG_COUNT = 256;

// Ethernet interface configuration
parameter XGMII_DATA_WIDTH = 64;
parameter XGMII_CTRL_WIDTH = XGMII_DATA_WIDTH/8;
parameter AXIS_ETH_DATA_WIDTH = XGMII_DATA_WIDTH;
parameter AXIS_ETH_KEEP_WIDTH = AXIS_ETH_DATA_WIDTH/8;
parameter AXIS_ETH_SYNC_DATA_WIDTH = AXIS_ETH_DATA_WIDTH*(AXIS_ETH_SYNC_DATA_WIDTH_DOUBLE ? 2 : 1);
parameter AXIS_ETH_TX_USER_WIDTH = TX_TAG_WIDTH + 1;
parameter AXIS_ETH_RX_USER_WIDTH = (PTP_TS_ENABLE ? PTP_TS_WIDTH : 0) + 1;

// Clock and reset
wire pcie_user_clk;
wire pcie_user_reset;

wire init_clk_bufg;

// Internal 125 MHz clock
wire clk_125mhz_mmcm_out;
wire clk_125mhz_int;
wire rst_125mhz_int;

wire mmcm_rst = pcie_user_reset || !pg[0] || !pg[1];
wire mmcm_locked;
wire mmcm_clkfb;

BUFG
init_clk_bufg_inst (
    .I(init_clk),
    .O(init_clk_bufg)
);

// MMCM instance
// 50 MHz in, 125 MHz out
// PFD range: 10 MHz to 500 MHz
// VCO range: 800 MHz to 1600 MHz
// M = 20, D = 1 sets Fvco = 1000 MHz (in range)
// Divide by 8 to get output frequency of 125 MHz
MMCME3_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKOUT0_DIVIDE_F(8),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0),
    .CLKOUT1_DIVIDE(1),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT1_PHASE(0),
    .CLKOUT2_DIVIDE(1),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT2_PHASE(0),
    .CLKOUT3_DIVIDE(1),
    .CLKOUT3_DUTY_CYCLE(0.5),
    .CLKOUT3_PHASE(0),
    .CLKOUT4_DIVIDE(1),
    .CLKOUT4_DUTY_CYCLE(0.5),
    .CLKOUT4_PHASE(0),
    .CLKOUT5_DIVIDE(1),
    .CLKOUT5_DUTY_CYCLE(0.5),
    .CLKOUT5_PHASE(0),
    .CLKOUT6_DIVIDE(1),
    .CLKOUT6_DUTY_CYCLE(0.5),
    .CLKOUT6_PHASE(0),
    .CLKFBOUT_MULT_F(20),
    .CLKFBOUT_PHASE(0),
    .DIVCLK_DIVIDE(1),
    .REF_JITTER1(0.010),
    .CLKIN1_PERIOD(20.000),
    .STARTUP_WAIT("FALSE"),
    .CLKOUT4_CASCADE("FALSE")
)
clk_mmcm_inst (
    .CLKIN1(init_clk_bufg),
    .CLKFBIN(mmcm_clkfb),
    .RST(mmcm_rst),
    .PWRDWN(1'b0),
    .CLKOUT0(clk_125mhz_mmcm_out),
    .CLKOUT0B(),
    .CLKOUT1(),
    .CLKOUT1B(),
    .CLKOUT2(),
    .CLKOUT2B(),
    .CLKOUT3(),
    .CLKOUT3B(),
    .CLKOUT4(),
    .CLKOUT5(),
    .CLKOUT6(),
    .CLKFBOUT(mmcm_clkfb),
    .CLKFBOUTB(),
    .LOCKED(mmcm_locked)
);

BUFG
clk_125mhz_bufg_inst (
    .I(clk_125mhz_mmcm_out),
    .O(clk_125mhz_int)
);

sync_reset #(
    .N(4)
)
sync_reset_125mhz_inst (
    .clk(clk_125mhz_int),
    .rst(~mmcm_locked),
    .out(rst_125mhz_int)
);

// GPIO
wire qsfp_0_mod_prsnt_n_int;
wire qsfp_0_intr_n_int;
wire qsfp_0_i2c_scl_i;
wire qsfp_0_i2c_scl_o;
wire qsfp_0_i2c_scl_t;
wire qsfp_0_i2c_sda_i;
wire qsfp_0_i2c_sda_o;
wire qsfp_0_i2c_sda_t;
wire qsfp_1_mod_prsnt_n_int;
wire qsfp_1_intr_n_int;
wire qsfp_1_i2c_scl_i;
wire qsfp_1_i2c_scl_o;
wire qsfp_1_i2c_scl_t;
wire qsfp_1_i2c_sda_i;
wire qsfp_1_i2c_sda_o;
wire qsfp_1_i2c_sda_t;

reg qsfp_0_i2c_scl_o_reg;
reg qsfp_0_i2c_scl_t_reg;
reg qsfp_0_i2c_sda_o_reg;
reg qsfp_0_i2c_sda_t_reg;
reg qsfp_1_i2c_scl_o_reg;
reg qsfp_1_i2c_scl_t_reg;
reg qsfp_1_i2c_sda_o_reg;
reg qsfp_1_i2c_sda_t_reg;

always @(posedge pcie_user_clk) begin
    qsfp_0_i2c_scl_o_reg <= qsfp_0_i2c_scl_o;
    qsfp_0_i2c_scl_t_reg <= qsfp_0_i2c_scl_t;
    qsfp_0_i2c_sda_o_reg <= qsfp_0_i2c_sda_o;
    qsfp_0_i2c_sda_t_reg <= qsfp_0_i2c_sda_t;
    qsfp_1_i2c_scl_o_reg <= qsfp_1_i2c_scl_o;
    qsfp_1_i2c_scl_t_reg <= qsfp_1_i2c_scl_t;
    qsfp_1_i2c_sda_o_reg <= qsfp_1_i2c_sda_o;
    qsfp_1_i2c_sda_t_reg <= qsfp_1_i2c_sda_t;
end

sync_signal #(
    .WIDTH(8),
    .N(2)
)
sync_signal_inst (
    .clk(pcie_user_clk),
    .in({qsfp_0_mod_prsnt_n, qsfp_0_intr_n, qsfp_0_i2c_scl, qsfp_0_i2c_sda,
        qsfp_1_mod_prsnt_n, qsfp_1_intr_n, qsfp_1_i2c_scl, qsfp_1_i2c_sda}),
    .out({qsfp_0_mod_prsnt_n_int, qsfp_0_intr_n_int, qsfp_0_i2c_scl_i, qsfp_0_i2c_sda_i,
        qsfp_1_mod_prsnt_n_int, qsfp_1_intr_n_int, qsfp_1_i2c_scl_i, qsfp_1_i2c_sda_i})
);

assign qsfp_0_i2c_scl = qsfp_0_i2c_scl_t_reg ? 1'bz : qsfp_0_i2c_scl_o_reg;
assign qsfp_0_i2c_sda = qsfp_0_i2c_sda_t_reg ? 1'bz : qsfp_0_i2c_sda_o_reg;
assign qsfp_1_i2c_scl = qsfp_1_i2c_scl_t_reg ? 1'bz : qsfp_1_i2c_scl_o_reg;
assign qsfp_1_i2c_sda = qsfp_1_i2c_sda_t_reg ? 1'bz : qsfp_1_i2c_sda_o_reg;

wire [7:0] led_red;
wire [7:0] led_green;

led_sreg_driver #(
    .COUNT(8),
    .INVERT(1),
    .REVERSE(0),
    .INTERLEAVE(1),
    .PRESCALE(63)
)
led_sreg_driver_inst (
    .clk(pcie_user_clk),
    .rst(pcie_user_reset),

    .led_a(led_red),
    .led_b(led_green),

    .sreg_d(led_sreg_d),
    .sreg_ld(led_sreg_ld),
    .sreg_clk(led_sreg_clk)
);

// Flash
wire qspi_clk_int;
wire [3:0] qspi_dq_int;
wire [3:0] qspi_dq_i_int;
wire [3:0] qspi_dq_o_int;
wire [3:0] qspi_dq_oe_int;
wire qspi_cs_int;

reg qspi_clk_reg;
reg [3:0] qspi_dq_o_reg;
reg [3:0] qspi_dq_oe_reg;
reg qspi_cs_reg;

always @(posedge pcie_user_clk) begin
    qspi_clk_reg <= qspi_clk_int;
    qspi_dq_o_reg <= qspi_dq_o_int;
    qspi_dq_oe_reg <= qspi_dq_oe_int;
    qspi_cs_reg <= qspi_cs_int;
end

sync_signal #(
    .WIDTH(4),
    .N(2)
)
flash_sync_signal_inst (
    .clk(pcie_user_clk),
    .in({qspi_dq_int}),
    .out({qspi_dq_i_int})
);

STARTUPE3
startupe3_inst (
    .CFGCLK(),
    .CFGMCLK(),
    .DI(qspi_dq_int),
    .DO(qspi_dq_o_reg),
    .DTS(~qspi_dq_oe_reg),
    .EOS(),
    .FCSBO(qspi_cs_reg),
    .FCSBTS(1'b0),
    .GSR(1'b0),
    .GTS(1'b0),
    .KEYCLEARB(1'b1),
    .PACK(1'b0),
    .PREQ(),
    .USRCCLKO(qspi_clk_reg),
    .USRCCLKTS(1'b0),
    .USRDONEO(1'b0),
    .USRDONETS(1'b1)
);

// FPGA boot
wire fpga_boot;

reg fpga_boot_sync_reg_0 = 1'b0;
reg fpga_boot_sync_reg_1 = 1'b0;
reg fpga_boot_sync_reg_2 = 1'b0;

wire icap_avail;
reg [2:0] icap_state = 0;
reg icap_csib_reg = 1'b1;
reg icap_rdwrb_reg = 1'b0;
reg [31:0] icap_di_reg = 32'hffffffff;

wire [31:0] icap_di_rev;

assign icap_di_rev[ 7] = icap_di_reg[ 0];
assign icap_di_rev[ 6] = icap_di_reg[ 1];
assign icap_di_rev[ 5] = icap_di_reg[ 2];
assign icap_di_rev[ 4] = icap_di_reg[ 3];
assign icap_di_rev[ 3] = icap_di_reg[ 4];
assign icap_di_rev[ 2] = icap_di_reg[ 5];
assign icap_di_rev[ 1] = icap_di_reg[ 6];
assign icap_di_rev[ 0] = icap_di_reg[ 7];

assign icap_di_rev[15] = icap_di_reg[ 8];
assign icap_di_rev[14] = icap_di_reg[ 9];
assign icap_di_rev[13] = icap_di_reg[10];
assign icap_di_rev[12] = icap_di_reg[11];
assign icap_di_rev[11] = icap_di_reg[12];
assign icap_di_rev[10] = icap_di_reg[13];
assign icap_di_rev[ 9] = icap_di_reg[14];
assign icap_di_rev[ 8] = icap_di_reg[15];

assign icap_di_rev[23] = icap_di_reg[16];
assign icap_di_rev[22] = icap_di_reg[17];
assign icap_di_rev[21] = icap_di_reg[18];
assign icap_di_rev[20] = icap_di_reg[19];
assign icap_di_rev[19] = icap_di_reg[20];
assign icap_di_rev[18] = icap_di_reg[21];
assign icap_di_rev[17] = icap_di_reg[22];
assign icap_di_rev[16] = icap_di_reg[23];

assign icap_di_rev[31] = icap_di_reg[24];
assign icap_di_rev[30] = icap_di_reg[25];
assign icap_di_rev[29] = icap_di_reg[26];
assign icap_di_rev[28] = icap_di_reg[27];
assign icap_di_rev[27] = icap_di_reg[28];
assign icap_di_rev[26] = icap_di_reg[29];
assign icap_di_rev[25] = icap_di_reg[30];
assign icap_di_rev[24] = icap_di_reg[31];

always @(posedge clk_125mhz_int) begin
    case (icap_state)
        0: begin
            icap_state <= 0;
            icap_csib_reg <= 1'b1;
            icap_rdwrb_reg <= 1'b0;
            icap_di_reg <= 32'hffffffff; // dummy word

            if (fpga_boot_sync_reg_2 && icap_avail) begin
                icap_state <= 1;
                icap_csib_reg <= 1'b0;
                icap_rdwrb_reg <= 1'b0;
                icap_di_reg <= 32'hffffffff; // dummy word
            end
        end
        1: begin
            icap_state <= 2;
            icap_csib_reg <= 1'b0;
            icap_rdwrb_reg <= 1'b0;
            icap_di_reg <= 32'hAA995566; // sync word
        end
        2: begin
            icap_state <= 3;
            icap_csib_reg <= 1'b0;
            icap_rdwrb_reg <= 1'b0;
            icap_di_reg <= 32'h20000000; // type 1 noop
        end
        3: begin
            icap_state <= 4;
            icap_csib_reg <= 1'b0;
            icap_rdwrb_reg <= 1'b0;
            icap_di_reg <= 32'h30008001; // write 1 word to CMD
        end
        4: begin
            icap_state <= 5;
            icap_csib_reg <= 1'b0;
            icap_rdwrb_reg <= 1'b0;
            icap_di_reg <= 32'h0000000F; // IPROG
        end
        5: begin
            icap_state <= 0;
            icap_csib_reg <= 1'b0;
            icap_rdwrb_reg <= 1'b0;
            icap_di_reg <= 32'h20000000; // type 1 noop
        end
    endcase

    fpga_boot_sync_reg_0 <= fpga_boot;
    fpga_boot_sync_reg_1 <= fpga_boot_sync_reg_0;
    fpga_boot_sync_reg_2 <= fpga_boot_sync_reg_1;
end

ICAPE3
icape3_inst (
    .AVAIL(icap_avail),
    .CLK(clk_125mhz_int),
    .CSIB(icap_csib_reg),
    .I(icap_di_rev),
    .O(),
    .PRDONE(),
    .PRERROR(),
    .RDWRB(icap_rdwrb_reg)
);

// PCIe
wire pcie_sys_clk;
wire pcie_sys_clk_gt;

IBUFDS_GTE4 #(
    .REFCLK_HROW_CK_SEL(2'b00)
)
ibufds_gte4_pcie_mgt_refclk_inst (
    .I             (pcie_refclk_p),
    .IB            (pcie_refclk_n),
    .CEB           (1'b0),
    .O             (pcie_sys_clk_gt),
    .ODIV2         (pcie_sys_clk)
);

wire [AXIS_PCIE_DATA_WIDTH-1:0]    axis_rq_tdata;
wire [AXIS_PCIE_KEEP_WIDTH-1:0]    axis_rq_tkeep;
wire                               axis_rq_tlast;
wire                               axis_rq_tready;
wire [AXIS_PCIE_RQ_USER_WIDTH-1:0] axis_rq_tuser;
wire                               axis_rq_tvalid;

wire [AXIS_PCIE_DATA_WIDTH-1:0]    axis_rc_tdata;
wire [AXIS_PCIE_KEEP_WIDTH-1:0]    axis_rc_tkeep;
wire                               axis_rc_tlast;
wire                               axis_rc_tready;
wire [AXIS_PCIE_RC_USER_WIDTH-1:0] axis_rc_tuser;
wire                               axis_rc_tvalid;

wire [AXIS_PCIE_DATA_WIDTH-1:0]    axis_cq_tdata;
wire [AXIS_PCIE_KEEP_WIDTH-1:0]    axis_cq_tkeep;
wire                               axis_cq_tlast;
wire                               axis_cq_tready;
wire [AXIS_PCIE_CQ_USER_WIDTH-1:0] axis_cq_tuser;
wire                               axis_cq_tvalid;

wire [AXIS_PCIE_DATA_WIDTH-1:0]    axis_cc_tdata;
wire [AXIS_PCIE_KEEP_WIDTH-1:0]    axis_cc_tkeep;
wire                               axis_cc_tlast;
wire                               axis_cc_tready;
wire [AXIS_PCIE_CC_USER_WIDTH-1:0] axis_cc_tuser;
wire                               axis_cc_tvalid;

wire [RQ_SEQ_NUM_WIDTH-1:0]        pcie_rq_seq_num0;
wire                               pcie_rq_seq_num_vld0;
wire [RQ_SEQ_NUM_WIDTH-1:0]        pcie_rq_seq_num1;
wire                               pcie_rq_seq_num_vld1;

wire [3:0] pcie_tfc_nph_av;
wire [3:0] pcie_tfc_npd_av;

wire [2:0] cfg_max_payload;
wire [2:0] cfg_max_read_req;
wire [3:0] cfg_rcb_status;

wire [9:0]  cfg_mgmt_addr;
wire [7:0]  cfg_mgmt_function_number;
wire        cfg_mgmt_write;
wire [31:0] cfg_mgmt_write_data;
wire [3:0]  cfg_mgmt_byte_enable;
wire        cfg_mgmt_read;
wire [31:0] cfg_mgmt_read_data;
wire        cfg_mgmt_read_write_done;

wire [7:0]  cfg_fc_ph;
wire [11:0] cfg_fc_pd;
wire [7:0]  cfg_fc_nph;
wire [11:0] cfg_fc_npd;
wire [7:0]  cfg_fc_cplh;
wire [11:0] cfg_fc_cpld;
wire [2:0]  cfg_fc_sel;

wire [3:0]   cfg_interrupt_msix_enable;
wire [3:0]   cfg_interrupt_msix_mask;
wire [251:0] cfg_interrupt_msix_vf_enable;
wire [251:0] cfg_interrupt_msix_vf_mask;
wire [63:0]  cfg_interrupt_msix_address;
wire [31:0]  cfg_interrupt_msix_data;
wire         cfg_interrupt_msix_int;
wire [1:0]   cfg_interrupt_msix_vec_pending;
wire         cfg_interrupt_msix_vec_pending_status;
wire         cfg_interrupt_msix_sent;
wire         cfg_interrupt_msix_fail;
wire [7:0]   cfg_interrupt_msi_function_number;

wire status_error_cor;
wire status_error_uncor;

// extra register for pcie_user_reset signal
wire pcie_user_reset_int;
(* shreg_extract = "no" *)
reg pcie_user_reset_reg_1 = 1'b1;
(* shreg_extract = "no" *)
reg pcie_user_reset_reg_2 = 1'b1;

always @(posedge pcie_user_clk) begin
    pcie_user_reset_reg_1 <= pcie_user_reset_int;
    pcie_user_reset_reg_2 <= pcie_user_reset_reg_1;
end

BUFG
pcie_user_reset_bufg_inst (
    .I(pcie_user_reset_reg_2),
    .O(pcie_user_reset)
);

// ila_0 ila_rq (
//     .clk(pcie_user_clk),
//     .trig_out(),
//     .trig_out_ack(1'b0),
//     .trig_in(1'b0),
//     .trig_in_ack(),
//     .probe0(axis_rq_tdata),
//     .probe1(axis_rq_tkeep),
//     .probe2(axis_rq_tvalid),
//     .probe3(axis_rq_tready),
//     .probe4({pcie_tfc_npd_av, pcie_tfc_nph_av, axis_rq_tuser}),
//     .probe5(axis_rq_tlast)
// );

// ila_0 ila_rc (
//     .clk(pcie_user_clk),
//     .trig_out(),
//     .trig_out_ack(1'b0),
//     .trig_in(1'b0),
//     .trig_in_ack(),
//     .probe0(axis_rc_tdata),
//     .probe1(axis_rc_tkeep),
//     .probe2(axis_rc_tvalid),
//     .probe3(axis_rc_tready),
//     .probe4(axis_rc_tuser),
//     .probe5(axis_rc_tlast)
// );

pcie4_uscale_plus_0
pcie4_uscale_plus_inst (
    .pci_exp_txn(pcie_tx_n),
    .pci_exp_txp(pcie_tx_p),
    .pci_exp_rxn(pcie_rx_n),
    .pci_exp_rxp(pcie_rx_p),
    .user_clk(pcie_user_clk),
    .user_reset(pcie_user_reset_int),
    .user_lnk_up(),

    .s_axis_rq_tdata(axis_rq_tdata),
    .s_axis_rq_tkeep(axis_rq_tkeep),
    .s_axis_rq_tlast(axis_rq_tlast),
    .s_axis_rq_tready(axis_rq_tready),
    .s_axis_rq_tuser(axis_rq_tuser),
    .s_axis_rq_tvalid(axis_rq_tvalid),

    .m_axis_rc_tdata(axis_rc_tdata),
    .m_axis_rc_tkeep(axis_rc_tkeep),
    .m_axis_rc_tlast(axis_rc_tlast),
    .m_axis_rc_tready(axis_rc_tready),
    .m_axis_rc_tuser(axis_rc_tuser),
    .m_axis_rc_tvalid(axis_rc_tvalid),

    .m_axis_cq_tdata(axis_cq_tdata),
    .m_axis_cq_tkeep(axis_cq_tkeep),
    .m_axis_cq_tlast(axis_cq_tlast),
    .m_axis_cq_tready(axis_cq_tready),
    .m_axis_cq_tuser(axis_cq_tuser),
    .m_axis_cq_tvalid(axis_cq_tvalid),

    .s_axis_cc_tdata(axis_cc_tdata),
    .s_axis_cc_tkeep(axis_cc_tkeep),
    .s_axis_cc_tlast(axis_cc_tlast),
    .s_axis_cc_tready(axis_cc_tready),
    .s_axis_cc_tuser(axis_cc_tuser),
    .s_axis_cc_tvalid(axis_cc_tvalid),

    .pcie_rq_seq_num0(pcie_rq_seq_num0),
    .pcie_rq_seq_num_vld0(pcie_rq_seq_num_vld0),
    .pcie_rq_seq_num1(pcie_rq_seq_num1),
    .pcie_rq_seq_num_vld1(pcie_rq_seq_num_vld1),
    .pcie_rq_tag0(),
    .pcie_rq_tag1(),
    .pcie_rq_tag_av(),
    .pcie_rq_tag_vld0(),
    .pcie_rq_tag_vld1(),

    .pcie_tfc_nph_av(pcie_tfc_nph_av),
    .pcie_tfc_npd_av(pcie_tfc_npd_av),

    .pcie_cq_np_req(1'b1),
    .pcie_cq_np_req_count(),

    .cfg_phy_link_down(),
    .cfg_phy_link_status(),
    .cfg_negotiated_width(),
    .cfg_current_speed(),
    .cfg_max_payload(cfg_max_payload),
    .cfg_max_read_req(cfg_max_read_req),
    .cfg_function_status(),
    .cfg_function_power_state(),
    .cfg_vf_status(),
    .cfg_vf_power_state(),
    .cfg_link_power_state(),

    .cfg_mgmt_addr(cfg_mgmt_addr),
    .cfg_mgmt_function_number(cfg_mgmt_function_number),
    .cfg_mgmt_write(cfg_mgmt_write),
    .cfg_mgmt_write_data(cfg_mgmt_write_data),
    .cfg_mgmt_byte_enable(cfg_mgmt_byte_enable),
    .cfg_mgmt_read(cfg_mgmt_read),
    .cfg_mgmt_read_data(cfg_mgmt_read_data),
    .cfg_mgmt_read_write_done(cfg_mgmt_read_write_done),
    .cfg_mgmt_debug_access(1'b0),

    .cfg_err_cor_out(),
    .cfg_err_nonfatal_out(),
    .cfg_err_fatal_out(),
    .cfg_local_error_valid(),
    .cfg_local_error_out(),
    .cfg_ltssm_state(),
    .cfg_rx_pm_state(),
    .cfg_tx_pm_state(),
    .cfg_rcb_status(cfg_rcb_status),
    .cfg_obff_enable(),
    .cfg_pl_status_change(),
    .cfg_tph_requester_enable(),
    .cfg_tph_st_mode(),
    .cfg_vf_tph_requester_enable(),
    .cfg_vf_tph_st_mode(),

    .cfg_msg_received(),
    .cfg_msg_received_data(),
    .cfg_msg_received_type(),
    .cfg_msg_transmit(1'b0),
    .cfg_msg_transmit_type(3'd0),
    .cfg_msg_transmit_data(32'd0),
    .cfg_msg_transmit_done(),

    .cfg_fc_ph(cfg_fc_ph),
    .cfg_fc_pd(cfg_fc_pd),
    .cfg_fc_nph(cfg_fc_nph),
    .cfg_fc_npd(cfg_fc_npd),
    .cfg_fc_cplh(cfg_fc_cplh),
    .cfg_fc_cpld(cfg_fc_cpld),
    .cfg_fc_sel(cfg_fc_sel),

    .cfg_dsn(64'd0),

    .cfg_power_state_change_ack(1'b1),
    .cfg_power_state_change_interrupt(),

    .cfg_err_cor_in(status_error_cor),
    .cfg_err_uncor_in(status_error_uncor),
    .cfg_flr_in_process(),
    .cfg_flr_done(4'd0),
    .cfg_vf_flr_in_process(),
    .cfg_vf_flr_func_num(8'd0),
    .cfg_vf_flr_done(8'd0),

    .cfg_link_training_enable(1'b1),

    .cfg_interrupt_int(4'd0),
    .cfg_interrupt_pending(4'd0),
    .cfg_interrupt_sent(),
    .cfg_interrupt_msix_enable(cfg_interrupt_msix_enable),
    .cfg_interrupt_msix_mask(cfg_interrupt_msix_mask),
    .cfg_interrupt_msix_vf_enable(cfg_interrupt_msix_vf_enable),
    .cfg_interrupt_msix_vf_mask(cfg_interrupt_msix_vf_mask),
    .cfg_interrupt_msix_address(cfg_interrupt_msix_address),
    .cfg_interrupt_msix_data(cfg_interrupt_msix_data),
    .cfg_interrupt_msix_int(cfg_interrupt_msix_int),
    .cfg_interrupt_msix_vec_pending(cfg_interrupt_msix_vec_pending),
    .cfg_interrupt_msix_vec_pending_status(cfg_interrupt_msix_vec_pending_status),
    .cfg_interrupt_msi_sent(cfg_interrupt_msix_sent),
    .cfg_interrupt_msi_fail(cfg_interrupt_msix_fail),
    .cfg_interrupt_msi_function_number(cfg_interrupt_msi_function_number),

    .cfg_pm_aspm_l1_entry_reject(1'b0),
    .cfg_pm_aspm_tx_l0s_entry_disable(1'b0),

    .cfg_hot_reset_out(),

    .cfg_config_space_enable(1'b1),
    .cfg_req_pm_transition_l23_ready(1'b0),
    .cfg_hot_reset_in(1'b0),

    .cfg_ds_port_number(8'd0),
    .cfg_ds_bus_number(8'd0),
    .cfg_ds_device_number(5'd0),

    .sys_clk(pcie_sys_clk),
    .sys_clk_gt(pcie_sys_clk_gt),
    .sys_reset(pcie_rst_n),

    .phy_rdy_out()
);

// XGMII 10G PHY

// QSFP0
wire                         qsfp_0_tx_clk_0_int;
wire                         qsfp_0_tx_rst_0_int;
wire [XGMII_DATA_WIDTH-1:0]  qsfp_0_txd_0_int;
wire [XGMII_CTRL_WIDTH-1:0]  qsfp_0_txc_0_int;
wire                         qsfp_0_cfg_tx_prbs31_enable_0_int;
wire                         qsfp_0_rx_clk_0_int;
wire                         qsfp_0_rx_rst_0_int;
wire [XGMII_DATA_WIDTH-1:0]  qsfp_0_rxd_0_int;
wire [XGMII_CTRL_WIDTH-1:0]  qsfp_0_rxc_0_int;
wire                         qsfp_0_cfg_rx_prbs31_enable_0_int;
wire [6:0]                   qsfp_0_rx_error_count_0_int;
wire                         qsfp_0_tx_clk_1_int;
wire                         qsfp_0_tx_rst_1_int;
wire [XGMII_DATA_WIDTH-1:0]  qsfp_0_txd_1_int;
wire [XGMII_CTRL_WIDTH-1:0]  qsfp_0_txc_1_int;
wire                         qsfp_0_cfg_tx_prbs31_enable_1_int;
wire                         qsfp_0_rx_clk_1_int;
wire                         qsfp_0_rx_rst_1_int;
wire [XGMII_DATA_WIDTH-1:0]  qsfp_0_rxd_1_int;
wire [XGMII_CTRL_WIDTH-1:0]  qsfp_0_rxc_1_int;
wire                         qsfp_0_cfg_rx_prbs31_enable_1_int;
wire [6:0]                   qsfp_0_rx_error_count_1_int;
wire                         qsfp_0_tx_clk_2_int;
wire                         qsfp_0_tx_rst_2_int;
wire [XGMII_DATA_WIDTH-1:0]  qsfp_0_txd_2_int;
wire [XGMII_CTRL_WIDTH-1:0]  qsfp_0_txc_2_int;
wire                         qsfp_0_cfg_tx_prbs31_enable_2_int;
wire                         qsfp_0_rx_clk_2_int;
wire                         qsfp_0_rx_rst_2_int;
wire [XGMII_DATA_WIDTH-1:0]  qsfp_0_rxd_2_int;
wire [XGMII_CTRL_WIDTH-1:0]  qsfp_0_rxc_2_int;
wire                         qsfp_0_cfg_rx_prbs31_enable_2_int;
wire [6:0]                   qsfp_0_rx_error_count_2_int;
wire                         qsfp_0_tx_clk_3_int;
wire                         qsfp_0_tx_rst_3_int;
wire [XGMII_DATA_WIDTH-1:0]  qsfp_0_txd_3_int;
wire [XGMII_CTRL_WIDTH-1:0]  qsfp_0_txc_3_int;
wire                         qsfp_0_cfg_tx_prbs31_enable_3_int;
wire                         qsfp_0_rx_clk_3_int;
wire                         qsfp_0_rx_rst_3_int;
wire [XGMII_DATA_WIDTH-1:0]  qsfp_0_rxd_3_int;
wire [XGMII_CTRL_WIDTH-1:0]  qsfp_0_rxc_3_int;
wire                         qsfp_0_cfg_rx_prbs31_enable_3_int;
wire [6:0]                   qsfp_0_rx_error_count_3_int;

wire        qsfp_0_drp_clk = clk_125mhz_int;
wire        qsfp_0_drp_rst = rst_125mhz_int;
wire [23:0] qsfp_0_drp_addr;
wire [15:0] qsfp_0_drp_di;
wire        qsfp_0_drp_en;
wire        qsfp_0_drp_we;
wire [15:0] qsfp_0_drp_do;
wire        qsfp_0_drp_rdy;

wire qsfp_0_rx_block_lock_0;
wire qsfp_0_rx_status_0;
wire qsfp_0_rx_block_lock_1;
wire qsfp_0_rx_status_1;
wire qsfp_0_rx_block_lock_2;
wire qsfp_0_rx_status_2;
wire qsfp_0_rx_block_lock_3;
wire qsfp_0_rx_status_3;

wire qsfp_0_gtpowergood;

wire qsfp_0_mgt_refclk;
wire qsfp_0_mgt_refclk_int;
wire qsfp_0_mgt_refclk_bufg;

IBUFDS_GTE4 ibufds_gte4_qsfp_0_mgt_refclk_inst (
    .I     (qsfp_0_mgt_refclk_p),
    .IB    (qsfp_0_mgt_refclk_n),
    .CEB   (1'b0),
    .O     (qsfp_0_mgt_refclk),
    .ODIV2 (qsfp_0_mgt_refclk_int)
);

BUFG_GT bufg_gt_qsfp_0_mgt_refclk_inst (
    .CE      (qsfp_0_gtpowergood),
    .CEMASK  (1'b1),
    .CLR     (1'b0),
    .CLRMASK (1'b1),
    .DIV     (3'd0),
    .I       (qsfp_0_mgt_refclk_int),
    .O       (qsfp_0_mgt_refclk_bufg)
);

wire qsfp_0_rst;

sync_reset #(
    .N(4)
)
qsfp_0_sync_reset_inst (
    .clk(qsfp_0_mgt_refclk_bufg),
    .rst(rst_125mhz_int),
    .out(qsfp_0_rst)
);

eth_xcvr_phy_10g_gty_quad_wrapper #(
    .PRBS31_ENABLE(1),
    .TX_SERDES_PIPELINE(1),
    .RX_SERDES_PIPELINE(1),
    .COUNT_125US(125000/2.56)
)
qsfp_0_phy_quad_inst (
    .xcvr_ctrl_clk(clk_125mhz_int),
    .xcvr_ctrl_rst(qsfp_0_rst),

    /*
     * Common
     */
    .xcvr_gtpowergood_out(qsfp_0_gtpowergood),
    .xcvr_gtrefclk00_in(qsfp_0_mgt_refclk),
    .xcvr_qpll0pd_in(1'b0),
    .xcvr_qpll0reset_in(1'b0),
    .xcvr_qpll0pcierate_in(3'd0),
    .xcvr_qpll0lock_out(),
    .xcvr_qpll0clk_out(),
    .xcvr_qpll0refclk_out(),
    .xcvr_gtrefclk01_in(qsfp_0_mgt_refclk),
    .xcvr_qpll1pd_in(1'b0),
    .xcvr_qpll1reset_in(1'b0),
    .xcvr_qpll1pcierate_in(3'd0),
    .xcvr_qpll1lock_out(),
    .xcvr_qpll1clk_out(),
    .xcvr_qpll1refclk_out(),

    /*
     * DRP
     */
    .drp_clk(qsfp_0_drp_clk),
    .drp_rst(qsfp_0_drp_rst),
    .drp_addr(qsfp_0_drp_addr),
    .drp_di(qsfp_0_drp_di),
    .drp_en(qsfp_0_drp_en),
    .drp_we(qsfp_0_drp_we),
    .drp_do(qsfp_0_drp_do),
    .drp_rdy(qsfp_0_drp_rdy),

    /*
     * Serial data
     */
    .xcvr_txp(qsfp_0_tx_p),
    .xcvr_txn(qsfp_0_tx_n),
    .xcvr_rxp(qsfp_0_rx_p),
    .xcvr_rxn(qsfp_0_rx_n),

    /*
     * PHY connections
     */
    .phy_1_tx_clk(qsfp_0_tx_clk_0_int),
    .phy_1_tx_rst(qsfp_0_tx_rst_0_int),
    .phy_1_xgmii_txd(qsfp_0_txd_0_int),
    .phy_1_xgmii_txc(qsfp_0_txc_0_int),
    .phy_1_rx_clk(qsfp_0_rx_clk_0_int),
    .phy_1_rx_rst(qsfp_0_rx_rst_0_int),
    .phy_1_xgmii_rxd(qsfp_0_rxd_0_int),
    .phy_1_xgmii_rxc(qsfp_0_rxc_0_int),
    .phy_1_tx_bad_block(),
    .phy_1_rx_error_count(qsfp_0_rx_error_count_0_int),
    .phy_1_rx_bad_block(),
    .phy_1_rx_sequence_error(),
    .phy_1_rx_block_lock(qsfp_0_rx_block_lock_0),
    .phy_1_rx_high_ber(),
    .phy_1_rx_status(qsfp_0_rx_status_0),
    .phy_1_cfg_tx_prbs31_enable(qsfp_0_cfg_tx_prbs31_enable_0_int),
    .phy_1_cfg_rx_prbs31_enable(qsfp_0_cfg_rx_prbs31_enable_0_int),

    .phy_2_tx_clk(qsfp_0_tx_clk_1_int),
    .phy_2_tx_rst(qsfp_0_tx_rst_1_int),
    .phy_2_xgmii_txd(qsfp_0_txd_1_int),
    .phy_2_xgmii_txc(qsfp_0_txc_1_int),
    .phy_2_rx_clk(qsfp_0_rx_clk_1_int),
    .phy_2_rx_rst(qsfp_0_rx_rst_1_int),
    .phy_2_xgmii_rxd(qsfp_0_rxd_1_int),
    .phy_2_xgmii_rxc(qsfp_0_rxc_1_int),
    .phy_2_tx_bad_block(),
    .phy_2_rx_error_count(qsfp_0_rx_error_count_1_int),
    .phy_2_rx_bad_block(),
    .phy_2_rx_sequence_error(),
    .phy_2_rx_block_lock(qsfp_0_rx_block_lock_1),
    .phy_2_rx_high_ber(),
    .phy_2_rx_status(qsfp_0_rx_status_1),
    .phy_2_cfg_tx_prbs31_enable(qsfp_0_cfg_tx_prbs31_enable_1_int),
    .phy_2_cfg_rx_prbs31_enable(qsfp_0_cfg_rx_prbs31_enable_1_int),

    .phy_3_tx_clk(qsfp_0_tx_clk_2_int),
    .phy_3_tx_rst(qsfp_0_tx_rst_2_int),
    .phy_3_xgmii_txd(qsfp_0_txd_2_int),
    .phy_3_xgmii_txc(qsfp_0_txc_2_int),
    .phy_3_rx_clk(qsfp_0_rx_clk_2_int),
    .phy_3_rx_rst(qsfp_0_rx_rst_2_int),
    .phy_3_xgmii_rxd(qsfp_0_rxd_2_int),
    .phy_3_xgmii_rxc(qsfp_0_rxc_2_int),
    .phy_3_tx_bad_block(),
    .phy_3_rx_error_count(qsfp_0_rx_error_count_2_int),
    .phy_3_rx_bad_block(),
    .phy_3_rx_sequence_error(),
    .phy_3_rx_block_lock(qsfp_0_rx_block_lock_2),
    .phy_3_rx_high_ber(),
    .phy_3_rx_status(qsfp_0_rx_status_2),
    .phy_3_cfg_tx_prbs31_enable(qsfp_0_cfg_tx_prbs31_enable_2_int),
    .phy_3_cfg_rx_prbs31_enable(qsfp_0_cfg_rx_prbs31_enable_2_int),

    .phy_4_tx_clk(qsfp_0_tx_clk_3_int),
    .phy_4_tx_rst(qsfp_0_tx_rst_3_int),
    .phy_4_xgmii_txd(qsfp_0_txd_3_int),
    .phy_4_xgmii_txc(qsfp_0_txc_3_int),
    .phy_4_rx_clk(qsfp_0_rx_clk_3_int),
    .phy_4_rx_rst(qsfp_0_rx_rst_3_int),
    .phy_4_xgmii_rxd(qsfp_0_rxd_3_int),
    .phy_4_xgmii_rxc(qsfp_0_rxc_3_int),
    .phy_4_tx_bad_block(),
    .phy_4_rx_error_count(qsfp_0_rx_error_count_3_int),
    .phy_4_rx_bad_block(),
    .phy_4_rx_sequence_error(),
    .phy_4_rx_block_lock(qsfp_0_rx_block_lock_3),
    .phy_4_rx_high_ber(),
    .phy_4_rx_status(qsfp_0_rx_status_3),
    .phy_4_cfg_tx_prbs31_enable(qsfp_0_cfg_tx_prbs31_enable_3_int),
    .phy_4_cfg_rx_prbs31_enable(qsfp_0_cfg_rx_prbs31_enable_3_int)
);

// QSFP1
wire                         qsfp_1_tx_clk_0_int;
wire                         qsfp_1_tx_rst_0_int;
wire [XGMII_DATA_WIDTH-1:0]  qsfp_1_txd_0_int;
wire [XGMII_CTRL_WIDTH-1:0]  qsfp_1_txc_0_int;
wire                         qsfp_1_cfg_tx_prbs31_enable_0_int;
wire                         qsfp_1_rx_clk_0_int;
wire                         qsfp_1_rx_rst_0_int;
wire [XGMII_DATA_WIDTH-1:0]  qsfp_1_rxd_0_int;
wire [XGMII_CTRL_WIDTH-1:0]  qsfp_1_rxc_0_int;
wire                         qsfp_1_cfg_rx_prbs31_enable_0_int;
wire [6:0]                   qsfp_1_rx_error_count_0_int;
wire                         qsfp_1_tx_clk_1_int;
wire                         qsfp_1_tx_rst_1_int;
wire [XGMII_DATA_WIDTH-1:0]  qsfp_1_txd_1_int;
wire [XGMII_CTRL_WIDTH-1:0]  qsfp_1_txc_1_int;
wire                         qsfp_1_cfg_tx_prbs31_enable_1_int;
wire                         qsfp_1_rx_clk_1_int;
wire                         qsfp_1_rx_rst_1_int;
wire [XGMII_DATA_WIDTH-1:0]  qsfp_1_rxd_1_int;
wire [XGMII_CTRL_WIDTH-1:0]  qsfp_1_rxc_1_int;
wire                         qsfp_1_cfg_rx_prbs31_enable_1_int;
wire [6:0]                   qsfp_1_rx_error_count_1_int;
wire                         qsfp_1_tx_clk_2_int;
wire                         qsfp_1_tx_rst_2_int;
wire [XGMII_DATA_WIDTH-1:0]  qsfp_1_txd_2_int;
wire [XGMII_CTRL_WIDTH-1:0]  qsfp_1_txc_2_int;
wire                         qsfp_1_cfg_tx_prbs31_enable_2_int;
wire                         qsfp_1_rx_clk_2_int;
wire                         qsfp_1_rx_rst_2_int;
wire [XGMII_DATA_WIDTH-1:0]  qsfp_1_rxd_2_int;
wire [XGMII_CTRL_WIDTH-1:0]  qsfp_1_rxc_2_int;
wire                         qsfp_1_cfg_rx_prbs31_enable_2_int;
wire [6:0]                   qsfp_1_rx_error_count_2_int;
wire                         qsfp_1_tx_clk_3_int;
wire                         qsfp_1_tx_rst_3_int;
wire [XGMII_DATA_WIDTH-1:0]  qsfp_1_txd_3_int;
wire [XGMII_CTRL_WIDTH-1:0]  qsfp_1_txc_3_int;
wire                         qsfp_1_cfg_tx_prbs31_enable_3_int;
wire                         qsfp_1_rx_clk_3_int;
wire                         qsfp_1_rx_rst_3_int;
wire [XGMII_DATA_WIDTH-1:0]  qsfp_1_rxd_3_int;
wire [XGMII_CTRL_WIDTH-1:0]  qsfp_1_rxc_3_int;
wire                         qsfp_1_cfg_rx_prbs31_enable_3_int;
wire [6:0]                   qsfp_1_rx_error_count_3_int;

wire        qsfp_1_drp_clk = clk_125mhz_int;
wire        qsfp_1_drp_rst = rst_125mhz_int;
wire [23:0] qsfp_1_drp_addr;
wire [15:0] qsfp_1_drp_di;
wire        qsfp_1_drp_en;
wire        qsfp_1_drp_we;
wire [15:0] qsfp_1_drp_do;
wire        qsfp_1_drp_rdy;

wire qsfp_1_rx_block_lock_0;
wire qsfp_1_rx_status_0;
wire qsfp_1_rx_block_lock_1;
wire qsfp_1_rx_status_1;
wire qsfp_1_rx_block_lock_2;
wire qsfp_1_rx_status_2;
wire qsfp_1_rx_block_lock_3;
wire qsfp_1_rx_status_3;

wire qsfp_1_gtpowergood;

wire qsfp_1_mgt_refclk;
wire qsfp_1_mgt_refclk_int;
wire qsfp_1_mgt_refclk_bufg;

IBUFDS_GTE4 ibufds_gte4_qsfp_1_mgt_refclk_inst (
    .I     (qsfp_1_mgt_refclk_p),
    .IB    (qsfp_1_mgt_refclk_n),
    .CEB   (1'b0),
    .O     (qsfp_1_mgt_refclk),
    .ODIV2 (qsfp_1_mgt_refclk_int)
);

BUFG_GT bufg_gt_qsfp_1_mgt_refclk_inst (
    .CE      (qsfp_1_gtpowergood),
    .CEMASK  (1'b1),
    .CLR     (1'b0),
    .CLRMASK (1'b1),
    .DIV     (3'd0),
    .I       (qsfp_1_mgt_refclk_int),
    .O       (qsfp_1_mgt_refclk_bufg)
);

wire qsfp_1_rst;

sync_reset #(
    .N(4)
)
qsfp_1_sync_reset_inst (
    .clk(qsfp_1_mgt_refclk_bufg),
    .rst(rst_125mhz_int),
    .out(qsfp_1_rst)
);

eth_xcvr_phy_10g_gty_quad_wrapper #(
    .PRBS31_ENABLE(1),
    .TX_SERDES_PIPELINE(1),
    .RX_SERDES_PIPELINE(1),
    .COUNT_125US(125000/2.56)
)
qsfp_1_phy_quad_inst (
    .xcvr_ctrl_clk(clk_125mhz_int),
    .xcvr_ctrl_rst(qsfp_1_rst),

    /*
     * Common
     */
    .xcvr_gtpowergood_out(qsfp_1_gtpowergood),
    .xcvr_gtrefclk00_in(qsfp_1_mgt_refclk),
    .xcvr_qpll0pd_in(1'b0),
    .xcvr_qpll0reset_in(1'b0),
    .xcvr_qpll0pcierate_in(3'd0),
    .xcvr_qpll0lock_out(),
    .xcvr_qpll0clk_out(),
    .xcvr_qpll0refclk_out(),
    .xcvr_gtrefclk01_in(qsfp_1_mgt_refclk),
    .xcvr_qpll1pd_in(1'b0),
    .xcvr_qpll1reset_in(1'b0),
    .xcvr_qpll1pcierate_in(3'd0),
    .xcvr_qpll1lock_out(),
    .xcvr_qpll1clk_out(),
    .xcvr_qpll1refclk_out(),

    /*
     * DRP
     */
    .drp_clk(qsfp_1_drp_clk),
    .drp_rst(qsfp_1_drp_rst),
    .drp_addr(qsfp_1_drp_addr),
    .drp_di(qsfp_1_drp_di),
    .drp_en(qsfp_1_drp_en),
    .drp_we(qsfp_1_drp_we),
    .drp_do(qsfp_1_drp_do),
    .drp_rdy(qsfp_1_drp_rdy),

    /*
     * Serial data
     */
    .xcvr_txp(qsfp_1_tx_p),
    .xcvr_txn(qsfp_1_tx_n),
    .xcvr_rxp(qsfp_1_rx_p),
    .xcvr_rxn(qsfp_1_rx_n),

    /*
     * PHY connections
     */
    .phy_1_tx_clk(qsfp_1_tx_clk_0_int),
    .phy_1_tx_rst(qsfp_1_tx_rst_0_int),
    .phy_1_xgmii_txd(qsfp_1_txd_0_int),
    .phy_1_xgmii_txc(qsfp_1_txc_0_int),
    .phy_1_rx_clk(qsfp_1_rx_clk_0_int),
    .phy_1_rx_rst(qsfp_1_rx_rst_0_int),
    .phy_1_xgmii_rxd(qsfp_1_rxd_0_int),
    .phy_1_xgmii_rxc(qsfp_1_rxc_0_int),
    .phy_1_tx_bad_block(),
    .phy_1_rx_error_count(qsfp_1_rx_error_count_0_int),
    .phy_1_rx_bad_block(),
    .phy_1_rx_sequence_error(),
    .phy_1_rx_block_lock(qsfp_1_rx_block_lock_0),
    .phy_1_rx_high_ber(),
    .phy_1_rx_status(qsfp_1_rx_status_0),
    .phy_1_cfg_tx_prbs31_enable(qsfp_1_cfg_tx_prbs31_enable_0_int),
    .phy_1_cfg_rx_prbs31_enable(qsfp_1_cfg_rx_prbs31_enable_0_int),

    .phy_2_tx_clk(qsfp_1_tx_clk_1_int),
    .phy_2_tx_rst(qsfp_1_tx_rst_1_int),
    .phy_2_xgmii_txd(qsfp_1_txd_1_int),
    .phy_2_xgmii_txc(qsfp_1_txc_1_int),
    .phy_2_rx_clk(qsfp_1_rx_clk_1_int),
    .phy_2_rx_rst(qsfp_1_rx_rst_1_int),
    .phy_2_xgmii_rxd(qsfp_1_rxd_1_int),
    .phy_2_xgmii_rxc(qsfp_1_rxc_1_int),
    .phy_2_tx_bad_block(),
    .phy_2_rx_error_count(qsfp_1_rx_error_count_1_int),
    .phy_2_rx_bad_block(),
    .phy_2_rx_sequence_error(),
    .phy_2_rx_block_lock(qsfp_1_rx_block_lock_1),
    .phy_2_rx_high_ber(),
    .phy_2_rx_status(qsfp_1_rx_status_1),
    .phy_2_cfg_tx_prbs31_enable(qsfp_1_cfg_tx_prbs31_enable_1_int),
    .phy_2_cfg_rx_prbs31_enable(qsfp_1_cfg_rx_prbs31_enable_1_int),

    .phy_3_tx_clk(qsfp_1_tx_clk_2_int),
    .phy_3_tx_rst(qsfp_1_tx_rst_2_int),
    .phy_3_xgmii_txd(qsfp_1_txd_2_int),
    .phy_3_xgmii_txc(qsfp_1_txc_2_int),
    .phy_3_rx_clk(qsfp_1_rx_clk_2_int),
    .phy_3_rx_rst(qsfp_1_rx_rst_2_int),
    .phy_3_xgmii_rxd(qsfp_1_rxd_2_int),
    .phy_3_xgmii_rxc(qsfp_1_rxc_2_int),
    .phy_3_tx_bad_block(),
    .phy_3_rx_error_count(qsfp_1_rx_error_count_2_int),
    .phy_3_rx_bad_block(),
    .phy_3_rx_sequence_error(),
    .phy_3_rx_block_lock(qsfp_1_rx_block_lock_2),
    .phy_3_rx_high_ber(),
    .phy_3_rx_status(qsfp_1_rx_status_2),
    .phy_3_cfg_tx_prbs31_enable(qsfp_1_cfg_tx_prbs31_enable_2_int),
    .phy_3_cfg_rx_prbs31_enable(qsfp_1_cfg_rx_prbs31_enable_2_int),

    .phy_4_tx_clk(qsfp_1_tx_clk_3_int),
    .phy_4_tx_rst(qsfp_1_tx_rst_3_int),
    .phy_4_xgmii_txd(qsfp_1_txd_3_int),
    .phy_4_xgmii_txc(qsfp_1_txc_3_int),
    .phy_4_rx_clk(qsfp_1_rx_clk_3_int),
    .phy_4_rx_rst(qsfp_1_rx_rst_3_int),
    .phy_4_xgmii_rxd(qsfp_1_rxd_3_int),
    .phy_4_xgmii_rxc(qsfp_1_rxc_3_int),
    .phy_4_tx_bad_block(),
    .phy_4_rx_error_count(qsfp_1_rx_error_count_3_int),
    .phy_4_rx_bad_block(),
    .phy_4_rx_sequence_error(),
    .phy_4_rx_block_lock(qsfp_1_rx_block_lock_3),
    .phy_4_rx_high_ber(),
    .phy_4_rx_status(qsfp_1_rx_status_3),
    .phy_4_cfg_tx_prbs31_enable(qsfp_1_cfg_tx_prbs31_enable_3_int),
    .phy_4_cfg_rx_prbs31_enable(qsfp_1_cfg_rx_prbs31_enable_3_int)
);

wire ptp_clk;
wire ptp_rst;
wire ptp_sample_clk;

assign ptp_clk = qsfp_0_mgt_refclk_bufg;
assign ptp_rst = qsfp_0_rst;
assign ptp_sample_clk = clk_125mhz_int;

assign led_green[0] = qsfp_0_rx_status_0;
assign led_green[1] = qsfp_0_rx_status_1;
assign led_green[2] = qsfp_0_rx_status_2;
assign led_green[3] = qsfp_0_rx_status_3;
assign led_green[4] = qsfp_1_rx_status_0;
assign led_green[5] = qsfp_1_rx_status_1;
assign led_green[6] = qsfp_1_rx_status_2;
assign led_green[7] = qsfp_1_rx_status_3;

// DDR4
wire [DDR_CH-1:0]                     ddr_clk;
wire [DDR_CH-1:0]                     ddr_rst;

wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]    m_axi_ddr_awid;
wire [DDR_CH*AXI_DDR_ADDR_WIDTH-1:0]  m_axi_ddr_awaddr;
wire [DDR_CH*8-1:0]                   m_axi_ddr_awlen;
wire [DDR_CH*3-1:0]                   m_axi_ddr_awsize;
wire [DDR_CH*2-1:0]                   m_axi_ddr_awburst;
wire [DDR_CH-1:0]                     m_axi_ddr_awlock;
wire [DDR_CH*4-1:0]                   m_axi_ddr_awcache;
wire [DDR_CH*3-1:0]                   m_axi_ddr_awprot;
wire [DDR_CH*4-1:0]                   m_axi_ddr_awqos;
wire [DDR_CH-1:0]                     m_axi_ddr_awvalid;
wire [DDR_CH-1:0]                     m_axi_ddr_awready;
wire [DDR_CH*AXI_DDR_DATA_WIDTH-1:0]  m_axi_ddr_wdata;
wire [DDR_CH*AXI_DDR_STRB_WIDTH-1:0]  m_axi_ddr_wstrb;
wire [DDR_CH-1:0]                     m_axi_ddr_wlast;
wire [DDR_CH-1:0]                     m_axi_ddr_wvalid;
wire [DDR_CH-1:0]                     m_axi_ddr_wready;
wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]    m_axi_ddr_bid;
wire [DDR_CH*2-1:0]                   m_axi_ddr_bresp;
wire [DDR_CH-1:0]                     m_axi_ddr_bvalid;
wire [DDR_CH-1:0]                     m_axi_ddr_bready;
wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]    m_axi_ddr_arid;
wire [DDR_CH*AXI_DDR_ADDR_WIDTH-1:0]  m_axi_ddr_araddr;
wire [DDR_CH*8-1:0]                   m_axi_ddr_arlen;
wire [DDR_CH*3-1:0]                   m_axi_ddr_arsize;
wire [DDR_CH*2-1:0]                   m_axi_ddr_arburst;
wire [DDR_CH-1:0]                     m_axi_ddr_arlock;
wire [DDR_CH*4-1:0]                   m_axi_ddr_arcache;
wire [DDR_CH*3-1:0]                   m_axi_ddr_arprot;
wire [DDR_CH*4-1:0]                   m_axi_ddr_arqos;
wire [DDR_CH-1:0]                     m_axi_ddr_arvalid;
wire [DDR_CH-1:0]                     m_axi_ddr_arready;
wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]    m_axi_ddr_rid;
wire [DDR_CH*AXI_DDR_DATA_WIDTH-1:0]  m_axi_ddr_rdata;
wire [DDR_CH*2-1:0]                   m_axi_ddr_rresp;
wire [DDR_CH-1:0]                     m_axi_ddr_rlast;
wire [DDR_CH-1:0]                     m_axi_ddr_rvalid;
wire [DDR_CH-1:0]                     m_axi_ddr_rready;

wire [DDR_CH-1:0]                     ddr_status;

generate

wire clk_ddr4_refclk1_ibufg;
wire clk_ddr4_refclk1;

IBUFGDS #(
   .DIFF_TERM("FALSE"),
   .IBUF_LOW_PWR("FALSE")
)
clk_ddr4_refclk1_ibufg_inst (
   .O   (clk_ddr4_refclk1_ibufg),
   .I   (clk_ddr4_refclk1_p),
   .IB  (clk_ddr4_refclk1_n)
);

BUFG
clk_ddr4_refclk1_bufg_inst (
    .I(clk_ddr4_refclk1_ibufg),
    .O(clk_ddr4_refclk1)
);

if (DDR_ENABLE && DDR_CH > 0) begin

reg ddr4_rst_reg = 1'b1;

always @(posedge pcie_user_clk or posedge pcie_user_reset) begin
    if (pcie_user_reset) begin
        ddr4_rst_reg <= 1'b1;
    end else begin
        ddr4_rst_reg <= 1'b0;
    end
end

ddr4_0 ddr4_c0_inst (
    .c0_sys_clk_i(clk_ddr4_refclk1),
    .sys_rst(ddr4_rst_reg),

    .c0_init_calib_complete(ddr_status[0 +: 1]),
    .c0_ddr4_interrupt(),
    .dbg_clk(),
    .dbg_bus(),

    .c0_ddr4_adr(ddr4_c0_adr),
    .c0_ddr4_ba(ddr4_c0_ba),
    .c0_ddr4_cke(ddr4_c0_cke),
    .c0_ddr4_cs_n(ddr4_c0_cs_n),
    .c0_ddr4_dq(ddr4_c0_dq),
    .c0_ddr4_dqs_t(ddr4_c0_dqs_t),
    .c0_ddr4_dqs_c(ddr4_c0_dqs_c),
    .c0_ddr4_dm_dbi_n(ddr4_c0_dm_dbi_n),
    .c0_ddr4_odt(ddr4_c0_odt),
    .c0_ddr4_bg(ddr4_c0_bg),
    .c0_ddr4_reset_n(ddr4_c0_reset_n),
    .c0_ddr4_act_n(ddr4_c0_act_n),
    .c0_ddr4_ck_t(ddr4_c0_ck_t),
    .c0_ddr4_ck_c(ddr4_c0_ck_c),

    .c0_ddr4_ui_clk(ddr_clk[0 +: 1]),
    .c0_ddr4_ui_clk_sync_rst(ddr_rst[0 +: 1]),

    .c0_ddr4_aresetn(!ddr_rst[0 +: 1]),

    .c0_ddr4_s_axi_ctrl_awvalid(1'b0),
    .c0_ddr4_s_axi_ctrl_awready(),
    .c0_ddr4_s_axi_ctrl_awaddr(32'd0),
    .c0_ddr4_s_axi_ctrl_wvalid(1'b0),
    .c0_ddr4_s_axi_ctrl_wready(),
    .c0_ddr4_s_axi_ctrl_wdata(32'd0),
    .c0_ddr4_s_axi_ctrl_bvalid(),
    .c0_ddr4_s_axi_ctrl_bready(1'b1),
    .c0_ddr4_s_axi_ctrl_bresp(),
    .c0_ddr4_s_axi_ctrl_arvalid(1'b0),
    .c0_ddr4_s_axi_ctrl_arready(),
    .c0_ddr4_s_axi_ctrl_araddr(31'd0),
    .c0_ddr4_s_axi_ctrl_rvalid(),
    .c0_ddr4_s_axi_ctrl_rready(1'b1),
    .c0_ddr4_s_axi_ctrl_rdata(),
    .c0_ddr4_s_axi_ctrl_rresp(),

    .c0_ddr4_s_axi_awid(m_axi_ddr_awid[0*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_awaddr(m_axi_ddr_awaddr[0*AXI_DDR_ADDR_WIDTH +: AXI_DDR_ADDR_WIDTH]),
    .c0_ddr4_s_axi_awlen(m_axi_ddr_awlen[0*8 +: 8]),
    .c0_ddr4_s_axi_awsize(m_axi_ddr_awsize[0*3 +: 3]),
    .c0_ddr4_s_axi_awburst(m_axi_ddr_awburst[0*2 +: 2]),
    .c0_ddr4_s_axi_awlock(m_axi_ddr_awlock[0 +: 1]),
    .c0_ddr4_s_axi_awcache(m_axi_ddr_awcache[0*4 +: 4]),
    .c0_ddr4_s_axi_awprot(m_axi_ddr_awprot[0*3 +: 3]),
    .c0_ddr4_s_axi_awqos(m_axi_ddr_awqos[0*4 +: 4]),
    .c0_ddr4_s_axi_awvalid(m_axi_ddr_awvalid[0 +: 1]),
    .c0_ddr4_s_axi_awready(m_axi_ddr_awready[0 +: 1]),
    .c0_ddr4_s_axi_wdata(m_axi_ddr_wdata[0*AXI_DDR_DATA_WIDTH +: AXI_DDR_DATA_WIDTH]),
    .c0_ddr4_s_axi_wstrb(m_axi_ddr_wstrb[0*AXI_DDR_STRB_WIDTH +: AXI_DDR_STRB_WIDTH]),
    .c0_ddr4_s_axi_wlast(m_axi_ddr_wlast[0 +: 1]),
    .c0_ddr4_s_axi_wvalid(m_axi_ddr_wvalid[0 +: 1]),
    .c0_ddr4_s_axi_wready(m_axi_ddr_wready[0 +: 1]),
    .c0_ddr4_s_axi_bready(m_axi_ddr_bready[0 +: 1]),
    .c0_ddr4_s_axi_bid(m_axi_ddr_bid[0*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_bresp(m_axi_ddr_bresp[0*2 +: 2]),
    .c0_ddr4_s_axi_bvalid(m_axi_ddr_bvalid[0 +: 1]),
    .c0_ddr4_s_axi_arid(m_axi_ddr_arid[0*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_araddr(m_axi_ddr_araddr[0*AXI_DDR_ADDR_WIDTH +: AXI_DDR_ADDR_WIDTH]),
    .c0_ddr4_s_axi_arlen(m_axi_ddr_arlen[0*8 +: 8]),
    .c0_ddr4_s_axi_arsize(m_axi_ddr_arsize[0*3 +: 3]),
    .c0_ddr4_s_axi_arburst(m_axi_ddr_arburst[0*2 +: 2]),
    .c0_ddr4_s_axi_arlock(m_axi_ddr_arlock[0 +: 1]),
    .c0_ddr4_s_axi_arcache(m_axi_ddr_arcache[0*4 +: 4]),
    .c0_ddr4_s_axi_arprot(m_axi_ddr_arprot[0*3 +: 3]),
    .c0_ddr4_s_axi_arqos(m_axi_ddr_arqos[0*4 +: 4]),
    .c0_ddr4_s_axi_arvalid(m_axi_ddr_arvalid[0 +: 1]),
    .c0_ddr4_s_axi_arready(m_axi_ddr_arready[0 +: 1]),
    .c0_ddr4_s_axi_rready(m_axi_ddr_rready[0 +: 1]),
    .c0_ddr4_s_axi_rlast(m_axi_ddr_rlast[0 +: 1]),
    .c0_ddr4_s_axi_rvalid(m_axi_ddr_rvalid[0 +: 1]),
    .c0_ddr4_s_axi_rresp(m_axi_ddr_rresp[0*2 +: 2]),
    .c0_ddr4_s_axi_rid(m_axi_ddr_rid[0*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_rdata(m_axi_ddr_rdata[0*AXI_DDR_DATA_WIDTH +: AXI_DDR_DATA_WIDTH])
);

end else begin

assign ddr4_c0_adr = {17{1'bz}};
assign ddr4_c0_ba = {2{1'bz}};
assign ddr4_c0_bg = {2{1'bz}};
assign ddr4_c0_cke = 1'bz;
assign ddr4_c0_cs_n = 1'bz;
assign ddr4_c0_act_n = 1'bz;
assign ddr4_c0_odt = 1'bz;
assign ddr4_c0_reset_n = 1'b0;
assign ddr4_c0_dq = {72{1'bz}};
assign ddr4_c0_dqs_t = {9{1'bz}};
assign ddr4_c0_dqs_c = {9{1'bz}};
assign ddr4_c0_dm_dbi_n = {9{1'bz}};

OBUFTDS ddr4_c0_ck_obuftds_inst (
    .I(1'b0),
    .T(1'b1),
    .O(ddr4_c0_ck_t),
    .OB(ddr4_c0_ck_c)
);

assign ddr_clk = 0;
assign ddr_rst = 0;

assign m_axi_ddr_awready = 0;
assign m_axi_ddr_wready = 0;
assign m_axi_ddr_bid = 0;
assign m_axi_ddr_bresp = 0;
assign m_axi_ddr_bvalid = 0;
assign m_axi_ddr_arready = 0;
assign m_axi_ddr_rid = 0;
assign m_axi_ddr_rdata = 0;
assign m_axi_ddr_rresp = 0;
assign m_axi_ddr_rlast = 0;
assign m_axi_ddr_rvalid = 0;

assign ddr_status = 0;

end

assign ddr4_c0_par = 1'b0;
assign ddr4_c0_ten = 1'b0;

if (DDR_ENABLE && DDR_CH > 1) begin

reg ddr4_rst_reg = 1'b1;

always @(posedge pcie_user_clk or posedge pcie_user_reset) begin
    if (pcie_user_reset) begin
        ddr4_rst_reg <= 1'b1;
    end else begin
        ddr4_rst_reg <= 1'b0;
    end
end

ddr4_0 ddr4_c1_inst (
    .c0_sys_clk_i(clk_ddr4_refclk1),
    .sys_rst(ddr4_rst_reg),

    .c0_init_calib_complete(ddr_status[1 +: 1]),
    .c0_ddr4_interrupt(),
    .dbg_clk(),
    .dbg_bus(),

    .c0_ddr4_adr(ddr4_c1_adr),
    .c0_ddr4_ba(ddr4_c1_ba),
    .c0_ddr4_cke(ddr4_c1_cke),
    .c0_ddr4_cs_n(ddr4_c1_cs_n),
    .c0_ddr4_dq(ddr4_c1_dq),
    .c0_ddr4_dqs_t(ddr4_c1_dqs_t),
    .c0_ddr4_dqs_c(ddr4_c1_dqs_c),
    .c0_ddr4_dm_dbi_n(ddr4_c1_dm_dbi_n),
    .c0_ddr4_odt(ddr4_c1_odt),
    .c0_ddr4_bg(ddr4_c1_bg),
    .c0_ddr4_reset_n(ddr4_c1_reset_n),
    .c0_ddr4_act_n(ddr4_c1_act_n),
    .c0_ddr4_ck_t(ddr4_c1_ck_t),
    .c0_ddr4_ck_c(ddr4_c1_ck_c),

    .c0_ddr4_ui_clk(ddr_clk[1 +: 1]),
    .c0_ddr4_ui_clk_sync_rst(ddr_rst[1 +: 1]),

    .c0_ddr4_aresetn(!ddr_rst[1 +: 1]),

    .c0_ddr4_s_axi_ctrl_awvalid(1'b0),
    .c0_ddr4_s_axi_ctrl_awready(),
    .c0_ddr4_s_axi_ctrl_awaddr(32'd0),
    .c0_ddr4_s_axi_ctrl_wvalid(1'b0),
    .c0_ddr4_s_axi_ctrl_wready(),
    .c0_ddr4_s_axi_ctrl_wdata(32'd0),
    .c0_ddr4_s_axi_ctrl_bvalid(),
    .c0_ddr4_s_axi_ctrl_bready(1'b1),
    .c0_ddr4_s_axi_ctrl_bresp(),
    .c0_ddr4_s_axi_ctrl_arvalid(1'b0),
    .c0_ddr4_s_axi_ctrl_arready(),
    .c0_ddr4_s_axi_ctrl_araddr(31'd0),
    .c0_ddr4_s_axi_ctrl_rvalid(),
    .c0_ddr4_s_axi_ctrl_rready(1'b1),
    .c0_ddr4_s_axi_ctrl_rdata(),
    .c0_ddr4_s_axi_ctrl_rresp(),

    .c0_ddr4_s_axi_awid(m_axi_ddr_awid[1*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_awaddr(m_axi_ddr_awaddr[1*AXI_DDR_ADDR_WIDTH +: AXI_DDR_ADDR_WIDTH]),
    .c0_ddr4_s_axi_awlen(m_axi_ddr_awlen[1*8 +: 8]),
    .c0_ddr4_s_axi_awsize(m_axi_ddr_awsize[1*3 +: 3]),
    .c0_ddr4_s_axi_awburst(m_axi_ddr_awburst[1*2 +: 2]),
    .c0_ddr4_s_axi_awlock(m_axi_ddr_awlock[1 +: 1]),
    .c0_ddr4_s_axi_awcache(m_axi_ddr_awcache[1*4 +: 4]),
    .c0_ddr4_s_axi_awprot(m_axi_ddr_awprot[1*3 +: 3]),
    .c0_ddr4_s_axi_awqos(m_axi_ddr_awqos[1*4 +: 4]),
    .c0_ddr4_s_axi_awvalid(m_axi_ddr_awvalid[1 +: 1]),
    .c0_ddr4_s_axi_awready(m_axi_ddr_awready[1 +: 1]),
    .c0_ddr4_s_axi_wdata(m_axi_ddr_wdata[1*AXI_DDR_DATA_WIDTH +: AXI_DDR_DATA_WIDTH]),
    .c0_ddr4_s_axi_wstrb(m_axi_ddr_wstrb[1*AXI_DDR_STRB_WIDTH +: AXI_DDR_STRB_WIDTH]),
    .c0_ddr4_s_axi_wlast(m_axi_ddr_wlast[1 +: 1]),
    .c0_ddr4_s_axi_wvalid(m_axi_ddr_wvalid[1 +: 1]),
    .c0_ddr4_s_axi_wready(m_axi_ddr_wready[1 +: 1]),
    .c0_ddr4_s_axi_bready(m_axi_ddr_bready[1 +: 1]),
    .c0_ddr4_s_axi_bid(m_axi_ddr_bid[1*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_bresp(m_axi_ddr_bresp[1*2 +: 2]),
    .c0_ddr4_s_axi_bvalid(m_axi_ddr_bvalid[1 +: 1]),
    .c0_ddr4_s_axi_arid(m_axi_ddr_arid[1*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_araddr(m_axi_ddr_araddr[1*AXI_DDR_ADDR_WIDTH +: AXI_DDR_ADDR_WIDTH]),
    .c0_ddr4_s_axi_arlen(m_axi_ddr_arlen[1*8 +: 8]),
    .c0_ddr4_s_axi_arsize(m_axi_ddr_arsize[1*3 +: 3]),
    .c0_ddr4_s_axi_arburst(m_axi_ddr_arburst[1*2 +: 2]),
    .c0_ddr4_s_axi_arlock(m_axi_ddr_arlock[1 +: 1]),
    .c0_ddr4_s_axi_arcache(m_axi_ddr_arcache[1*4 +: 4]),
    .c0_ddr4_s_axi_arprot(m_axi_ddr_arprot[1*3 +: 3]),
    .c0_ddr4_s_axi_arqos(m_axi_ddr_arqos[1*4 +: 4]),
    .c0_ddr4_s_axi_arvalid(m_axi_ddr_arvalid[1 +: 1]),
    .c0_ddr4_s_axi_arready(m_axi_ddr_arready[1 +: 1]),
    .c0_ddr4_s_axi_rready(m_axi_ddr_rready[1 +: 1]),
    .c0_ddr4_s_axi_rlast(m_axi_ddr_rlast[1 +: 1]),
    .c0_ddr4_s_axi_rvalid(m_axi_ddr_rvalid[1 +: 1]),
    .c0_ddr4_s_axi_rresp(m_axi_ddr_rresp[1*2 +: 2]),
    .c0_ddr4_s_axi_rid(m_axi_ddr_rid[1*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_rdata(m_axi_ddr_rdata[1*AXI_DDR_DATA_WIDTH +: AXI_DDR_DATA_WIDTH])
);

end else begin

assign ddr4_c1_adr = {17{1'bz}};
assign ddr4_c1_ba = {2{1'bz}};
assign ddr4_c1_bg = {2{1'bz}};
assign ddr4_c1_cke = 1'bz;
assign ddr4_c1_cs_n = 1'bz;
assign ddr4_c1_act_n = 1'bz;
assign ddr4_c1_odt = 1'bz;
assign ddr4_c1_reset_n = 1'b0;
assign ddr4_c1_dq = {72{1'bz}};
assign ddr4_c1_dqs_t = {9{1'bz}};
assign ddr4_c1_dqs_c = {9{1'bz}};
assign ddr4_c1_dm_dbi_n = {9{1'bz}};

OBUFTDS ddr4_c1_ck_obuftds_inst (
    .I(1'b0),
    .T(1'b1),
    .O(ddr4_c1_ck_t),
    .OB(ddr4_c1_ck_c)
);

end

assign ddr4_c1_par = 1'b0;
assign ddr4_c1_ten = 1'b0;

wire clk_ddr4_refclk2_ibufg;
wire clk_ddr4_refclk2;

IBUFGDS #(
   .DIFF_TERM("FALSE"),
   .IBUF_LOW_PWR("FALSE")
)
clk_ddr4_refclk2_ibufg_inst (
   .O   (clk_ddr4_refclk2_ibufg),
   .I   (clk_ddr4_refclk2_p),
   .IB  (clk_ddr4_refclk2_n)
);

BUFG
clk_ddr4_refclk2_bufg_inst (
    .I(clk_ddr4_refclk2_ibufg),
    .O(clk_ddr4_refclk2)
);

if (DDR_ENABLE && DDR_CH > 2) begin

reg ddr4_rst_reg = 1'b1;

always @(posedge pcie_user_clk or posedge pcie_user_reset) begin
    if (pcie_user_reset) begin
        ddr4_rst_reg <= 1'b1;
    end else begin
        ddr4_rst_reg <= 1'b0;
    end
end

ddr4_0 ddr4_c2_inst (
    .c0_sys_clk_i(clk_ddr4_refclk2),
    .sys_rst(ddr4_rst_reg),

    .c0_init_calib_complete(ddr_status[2 +: 1]),
    .c0_ddr4_interrupt(),
    .dbg_clk(),
    .dbg_bus(),

    .c0_ddr4_adr(ddr4_c2_adr),
    .c0_ddr4_ba(ddr4_c2_ba),
    .c0_ddr4_cke(ddr4_c2_cke),
    .c0_ddr4_cs_n(ddr4_c2_cs_n),
    .c0_ddr4_dq(ddr4_c2_dq),
    .c0_ddr4_dqs_t(ddr4_c2_dqs_t),
    .c0_ddr4_dqs_c(ddr4_c2_dqs_c),
    .c0_ddr4_dm_dbi_n(ddr4_c2_dm_dbi_n),
    .c0_ddr4_odt(ddr4_c2_odt),
    .c0_ddr4_bg(ddr4_c2_bg),
    .c0_ddr4_reset_n(ddr4_c2_reset_n),
    .c0_ddr4_act_n(ddr4_c2_act_n),
    .c0_ddr4_ck_t(ddr4_c2_ck_t),
    .c0_ddr4_ck_c(ddr4_c2_ck_c),

    .c0_ddr4_ui_clk(ddr_clk[2 +: 1]),
    .c0_ddr4_ui_clk_sync_rst(ddr_rst[2 +: 1]),

    .c0_ddr4_aresetn(!ddr_rst[2 +: 1]),

    .c0_ddr4_s_axi_ctrl_awvalid(1'b0),
    .c0_ddr4_s_axi_ctrl_awready(),
    .c0_ddr4_s_axi_ctrl_awaddr(32'd0),
    .c0_ddr4_s_axi_ctrl_wvalid(1'b0),
    .c0_ddr4_s_axi_ctrl_wready(),
    .c0_ddr4_s_axi_ctrl_wdata(32'd0),
    .c0_ddr4_s_axi_ctrl_bvalid(),
    .c0_ddr4_s_axi_ctrl_bready(1'b1),
    .c0_ddr4_s_axi_ctrl_bresp(),
    .c0_ddr4_s_axi_ctrl_arvalid(1'b0),
    .c0_ddr4_s_axi_ctrl_arready(),
    .c0_ddr4_s_axi_ctrl_araddr(31'd0),
    .c0_ddr4_s_axi_ctrl_rvalid(),
    .c0_ddr4_s_axi_ctrl_rready(1'b1),
    .c0_ddr4_s_axi_ctrl_rdata(),
    .c0_ddr4_s_axi_ctrl_rresp(),

    .c0_ddr4_s_axi_awid(m_axi_ddr_awid[2*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_awaddr(m_axi_ddr_awaddr[2*AXI_DDR_ADDR_WIDTH +: AXI_DDR_ADDR_WIDTH]),
    .c0_ddr4_s_axi_awlen(m_axi_ddr_awlen[2*8 +: 8]),
    .c0_ddr4_s_axi_awsize(m_axi_ddr_awsize[2*3 +: 3]),
    .c0_ddr4_s_axi_awburst(m_axi_ddr_awburst[2*2 +: 2]),
    .c0_ddr4_s_axi_awlock(m_axi_ddr_awlock[2 +: 1]),
    .c0_ddr4_s_axi_awcache(m_axi_ddr_awcache[2*4 +: 4]),
    .c0_ddr4_s_axi_awprot(m_axi_ddr_awprot[2*3 +: 3]),
    .c0_ddr4_s_axi_awqos(m_axi_ddr_awqos[2*4 +: 4]),
    .c0_ddr4_s_axi_awvalid(m_axi_ddr_awvalid[2 +: 1]),
    .c0_ddr4_s_axi_awready(m_axi_ddr_awready[2 +: 1]),
    .c0_ddr4_s_axi_wdata(m_axi_ddr_wdata[2*AXI_DDR_DATA_WIDTH +: AXI_DDR_DATA_WIDTH]),
    .c0_ddr4_s_axi_wstrb(m_axi_ddr_wstrb[2*AXI_DDR_STRB_WIDTH +: AXI_DDR_STRB_WIDTH]),
    .c0_ddr4_s_axi_wlast(m_axi_ddr_wlast[2 +: 1]),
    .c0_ddr4_s_axi_wvalid(m_axi_ddr_wvalid[2 +: 1]),
    .c0_ddr4_s_axi_wready(m_axi_ddr_wready[2 +: 1]),
    .c0_ddr4_s_axi_bready(m_axi_ddr_bready[2 +: 1]),
    .c0_ddr4_s_axi_bid(m_axi_ddr_bid[2*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_bresp(m_axi_ddr_bresp[2*2 +: 2]),
    .c0_ddr4_s_axi_bvalid(m_axi_ddr_bvalid[2 +: 1]),
    .c0_ddr4_s_axi_arid(m_axi_ddr_arid[2*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_araddr(m_axi_ddr_araddr[2*AXI_DDR_ADDR_WIDTH +: AXI_DDR_ADDR_WIDTH]),
    .c0_ddr4_s_axi_arlen(m_axi_ddr_arlen[2*8 +: 8]),
    .c0_ddr4_s_axi_arsize(m_axi_ddr_arsize[2*3 +: 3]),
    .c0_ddr4_s_axi_arburst(m_axi_ddr_arburst[2*2 +: 2]),
    .c0_ddr4_s_axi_arlock(m_axi_ddr_arlock[2 +: 1]),
    .c0_ddr4_s_axi_arcache(m_axi_ddr_arcache[2*4 +: 4]),
    .c0_ddr4_s_axi_arprot(m_axi_ddr_arprot[2*3 +: 3]),
    .c0_ddr4_s_axi_arqos(m_axi_ddr_arqos[2*4 +: 4]),
    .c0_ddr4_s_axi_arvalid(m_axi_ddr_arvalid[2 +: 1]),
    .c0_ddr4_s_axi_arready(m_axi_ddr_arready[2 +: 1]),
    .c0_ddr4_s_axi_rready(m_axi_ddr_rready[2 +: 1]),
    .c0_ddr4_s_axi_rlast(m_axi_ddr_rlast[2 +: 1]),
    .c0_ddr4_s_axi_rvalid(m_axi_ddr_rvalid[2 +: 1]),
    .c0_ddr4_s_axi_rresp(m_axi_ddr_rresp[2*2 +: 2]),
    .c0_ddr4_s_axi_rid(m_axi_ddr_rid[2*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_rdata(m_axi_ddr_rdata[2*AXI_DDR_DATA_WIDTH +: AXI_DDR_DATA_WIDTH])
);

end else begin

assign ddr4_c2_adr = {17{1'bz}};
assign ddr4_c2_ba = {2{1'bz}};
assign ddr4_c2_bg = {2{1'bz}};
assign ddr4_c2_cke = 1'bz;
assign ddr4_c2_cs_n = 1'bz;
assign ddr4_c2_act_n = 1'bz;
assign ddr4_c2_odt = 1'bz;
assign ddr4_c2_reset_n = 1'b0;
assign ddr4_c2_dq = {72{1'bz}};
assign ddr4_c2_dqs_t = {9{1'bz}};
assign ddr4_c2_dqs_c = {9{1'bz}};
assign ddr4_c2_dm_dbi_n = {9{1'bz}};

OBUFTDS ddr4_c2_ck_obuftds_inst (
    .I(1'b0),
    .T(1'b1),
    .O(ddr4_c2_ck_t),
    .OB(ddr4_c2_ck_c)
);

end

assign ddr4_c2_par = 1'b0;
assign ddr4_c2_ten = 1'b0;

if (DDR_ENABLE && DDR_CH > 3) begin

reg ddr4_rst_reg = 1'b1;

always @(posedge pcie_user_clk or posedge pcie_user_reset) begin
    if (pcie_user_reset) begin
        ddr4_rst_reg <= 1'b1;
    end else begin
        ddr4_rst_reg <= 1'b0;
    end
end

ddr4_0 ddr4_c3_inst (
    .c0_sys_clk_i(clk_ddr4_refclk2),
    .sys_rst(ddr4_rst_reg),

    .c0_init_calib_complete(ddr_status[3 +: 1]),
    .c0_ddr4_interrupt(),
    .dbg_clk(),
    .dbg_bus(),

    .c0_ddr4_adr(ddr4_c3_adr),
    .c0_ddr4_ba(ddr4_c3_ba),
    .c0_ddr4_cke(ddr4_c3_cke),
    .c0_ddr4_cs_n(ddr4_c3_cs_n),
    .c0_ddr4_dq(ddr4_c3_dq),
    .c0_ddr4_dqs_t(ddr4_c3_dqs_t),
    .c0_ddr4_dqs_c(ddr4_c3_dqs_c),
    .c0_ddr4_dm_dbi_n(ddr4_c3_dm_dbi_n),
    .c0_ddr4_odt(ddr4_c3_odt),
    .c0_ddr4_bg(ddr4_c3_bg),
    .c0_ddr4_reset_n(ddr4_c3_reset_n),
    .c0_ddr4_act_n(ddr4_c3_act_n),
    .c0_ddr4_ck_t(ddr4_c3_ck_t),
    .c0_ddr4_ck_c(ddr4_c3_ck_c),

    .c0_ddr4_ui_clk(ddr_clk[3 +: 1]),
    .c0_ddr4_ui_clk_sync_rst(ddr_rst[3 +: 1]),

    .c0_ddr4_aresetn(!ddr_rst[3 +: 1]),

    .c0_ddr4_s_axi_ctrl_awvalid(1'b0),
    .c0_ddr4_s_axi_ctrl_awready(),
    .c0_ddr4_s_axi_ctrl_awaddr(32'd0),
    .c0_ddr4_s_axi_ctrl_wvalid(1'b0),
    .c0_ddr4_s_axi_ctrl_wready(),
    .c0_ddr4_s_axi_ctrl_wdata(32'd0),
    .c0_ddr4_s_axi_ctrl_bvalid(),
    .c0_ddr4_s_axi_ctrl_bready(1'b1),
    .c0_ddr4_s_axi_ctrl_bresp(),
    .c0_ddr4_s_axi_ctrl_arvalid(1'b0),
    .c0_ddr4_s_axi_ctrl_arready(),
    .c0_ddr4_s_axi_ctrl_araddr(31'd0),
    .c0_ddr4_s_axi_ctrl_rvalid(),
    .c0_ddr4_s_axi_ctrl_rready(1'b1),
    .c0_ddr4_s_axi_ctrl_rdata(),
    .c0_ddr4_s_axi_ctrl_rresp(),

    .c0_ddr4_s_axi_awid(m_axi_ddr_awid[3*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_awaddr(m_axi_ddr_awaddr[3*AXI_DDR_ADDR_WIDTH +: AXI_DDR_ADDR_WIDTH]),
    .c0_ddr4_s_axi_awlen(m_axi_ddr_awlen[3*8 +: 8]),
    .c0_ddr4_s_axi_awsize(m_axi_ddr_awsize[3*3 +: 3]),
    .c0_ddr4_s_axi_awburst(m_axi_ddr_awburst[3*2 +: 2]),
    .c0_ddr4_s_axi_awlock(m_axi_ddr_awlock[3 +: 1]),
    .c0_ddr4_s_axi_awcache(m_axi_ddr_awcache[3*4 +: 4]),
    .c0_ddr4_s_axi_awprot(m_axi_ddr_awprot[3*3 +: 3]),
    .c0_ddr4_s_axi_awqos(m_axi_ddr_awqos[3*4 +: 4]),
    .c0_ddr4_s_axi_awvalid(m_axi_ddr_awvalid[3 +: 1]),
    .c0_ddr4_s_axi_awready(m_axi_ddr_awready[3 +: 1]),
    .c0_ddr4_s_axi_wdata(m_axi_ddr_wdata[3*AXI_DDR_DATA_WIDTH +: AXI_DDR_DATA_WIDTH]),
    .c0_ddr4_s_axi_wstrb(m_axi_ddr_wstrb[3*AXI_DDR_STRB_WIDTH +: AXI_DDR_STRB_WIDTH]),
    .c0_ddr4_s_axi_wlast(m_axi_ddr_wlast[3 +: 1]),
    .c0_ddr4_s_axi_wvalid(m_axi_ddr_wvalid[3 +: 1]),
    .c0_ddr4_s_axi_wready(m_axi_ddr_wready[3 +: 1]),
    .c0_ddr4_s_axi_bready(m_axi_ddr_bready[3 +: 1]),
    .c0_ddr4_s_axi_bid(m_axi_ddr_bid[3*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_bresp(m_axi_ddr_bresp[3*2 +: 2]),
    .c0_ddr4_s_axi_bvalid(m_axi_ddr_bvalid[3 +: 1]),
    .c0_ddr4_s_axi_arid(m_axi_ddr_arid[3*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_araddr(m_axi_ddr_araddr[3*AXI_DDR_ADDR_WIDTH +: AXI_DDR_ADDR_WIDTH]),
    .c0_ddr4_s_axi_arlen(m_axi_ddr_arlen[3*8 +: 8]),
    .c0_ddr4_s_axi_arsize(m_axi_ddr_arsize[3*3 +: 3]),
    .c0_ddr4_s_axi_arburst(m_axi_ddr_arburst[3*2 +: 2]),
    .c0_ddr4_s_axi_arlock(m_axi_ddr_arlock[3 +: 1]),
    .c0_ddr4_s_axi_arcache(m_axi_ddr_arcache[3*4 +: 4]),
    .c0_ddr4_s_axi_arprot(m_axi_ddr_arprot[3*3 +: 3]),
    .c0_ddr4_s_axi_arqos(m_axi_ddr_arqos[3*4 +: 4]),
    .c0_ddr4_s_axi_arvalid(m_axi_ddr_arvalid[3 +: 1]),
    .c0_ddr4_s_axi_arready(m_axi_ddr_arready[3 +: 1]),
    .c0_ddr4_s_axi_rready(m_axi_ddr_rready[3 +: 1]),
    .c0_ddr4_s_axi_rlast(m_axi_ddr_rlast[3 +: 1]),
    .c0_ddr4_s_axi_rvalid(m_axi_ddr_rvalid[3 +: 1]),
    .c0_ddr4_s_axi_rresp(m_axi_ddr_rresp[3*2 +: 2]),
    .c0_ddr4_s_axi_rid(m_axi_ddr_rid[3*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
    .c0_ddr4_s_axi_rdata(m_axi_ddr_rdata[3*AXI_DDR_DATA_WIDTH +: AXI_DDR_DATA_WIDTH])
);

end else begin

assign ddr4_c3_adr = {17{1'bz}};
assign ddr4_c3_ba = {2{1'bz}};
assign ddr4_c3_bg = {2{1'bz}};
assign ddr4_c3_cke = 1'bz;
assign ddr4_c3_cs_n = 1'bz;
assign ddr4_c3_act_n = 1'bz;
assign ddr4_c3_odt = 1'bz;
assign ddr4_c3_reset_n = 1'b0;
assign ddr4_c3_dq = {72{1'bz}};
assign ddr4_c3_dqs_t = {9{1'bz}};
assign ddr4_c3_dqs_c = {9{1'bz}};
assign ddr4_c3_dm_dbi_n = {9{1'bz}};

OBUFTDS ddr4_c3_ck_obuftds_inst (
    .I(1'b0),
    .T(1'b1),
    .O(ddr4_c3_ck_t),
    .OB(ddr4_c3_ck_c)
);

end

assign ddr4_c3_par = 1'b0;
assign ddr4_c3_ten = 1'b0;

endgenerate

fpga_core #(
    // FW and board IDs
    .FPGA_ID(FPGA_ID),
    .FW_ID(FW_ID),
    .FW_VER(FW_VER),
    .BOARD_ID(BOARD_ID),
    .BOARD_VER(BOARD_VER),
    .BUILD_DATE(BUILD_DATE),
    .GIT_HASH(GIT_HASH),
    .RELEASE_INFO(RELEASE_INFO),

    // Board configuration
    .TDMA_BER_ENABLE(TDMA_BER_ENABLE),

    // Structural configuration
    .IF_COUNT(IF_COUNT),
    .PORTS_PER_IF(PORTS_PER_IF),
    .SCHED_PER_IF(SCHED_PER_IF),
    .PORT_MASK(PORT_MASK),

    // Clock configuration
    .CLK_PERIOD_NS_NUM(CLK_PERIOD_NS_NUM),
    .CLK_PERIOD_NS_DENOM(CLK_PERIOD_NS_DENOM),

    // PTP configuration
    .PTP_CLK_PERIOD_NS_NUM(PTP_CLK_PERIOD_NS_NUM),
    .PTP_CLK_PERIOD_NS_DENOM(PTP_CLK_PERIOD_NS_DENOM),
    .PTP_TS_WIDTH(PTP_TS_WIDTH),
    .PTP_CLOCK_PIPELINE(PTP_CLOCK_PIPELINE),
    .PTP_CLOCK_CDC_PIPELINE(PTP_CLOCK_CDC_PIPELINE),
    .PTP_PORT_CDC_PIPELINE(PTP_PORT_CDC_PIPELINE),
    .PTP_PEROUT_ENABLE(PTP_PEROUT_ENABLE),
    .PTP_PEROUT_COUNT(PTP_PEROUT_COUNT),
    .IF_PTP_PERIOD_NS(IF_PTP_PERIOD_NS),
    .IF_PTP_PERIOD_FNS(IF_PTP_PERIOD_FNS),

    // Queue manager configuration
    .EVENT_QUEUE_OP_TABLE_SIZE(EVENT_QUEUE_OP_TABLE_SIZE),
    .TX_QUEUE_OP_TABLE_SIZE(TX_QUEUE_OP_TABLE_SIZE),
    .RX_QUEUE_OP_TABLE_SIZE(RX_QUEUE_OP_TABLE_SIZE),
    .CQ_OP_TABLE_SIZE(CQ_OP_TABLE_SIZE),
    .EQN_WIDTH(EQN_WIDTH),
    .TX_QUEUE_INDEX_WIDTH(TX_QUEUE_INDEX_WIDTH),
    .RX_QUEUE_INDEX_WIDTH(RX_QUEUE_INDEX_WIDTH),
    .CQN_WIDTH(CQN_WIDTH),
    .EQ_PIPELINE(EQ_PIPELINE),
    .TX_QUEUE_PIPELINE(TX_QUEUE_PIPELINE),
    .RX_QUEUE_PIPELINE(RX_QUEUE_PIPELINE),
    .CQ_PIPELINE(CQ_PIPELINE),

    // TX and RX engine configuration
    .TX_DESC_TABLE_SIZE(TX_DESC_TABLE_SIZE),
    .RX_DESC_TABLE_SIZE(RX_DESC_TABLE_SIZE),
    .RX_INDIR_TBL_ADDR_WIDTH(RX_INDIR_TBL_ADDR_WIDTH),

    // Scheduler configuration
    .TX_SCHEDULER_OP_TABLE_SIZE(TX_SCHEDULER_OP_TABLE_SIZE),
    .TX_SCHEDULER_PIPELINE(TX_SCHEDULER_PIPELINE),
    .TDMA_INDEX_WIDTH(TDMA_INDEX_WIDTH),

    // Interface configuration
    .PTP_TS_ENABLE(PTP_TS_ENABLE),
    .TX_CPL_FIFO_DEPTH(TX_CPL_FIFO_DEPTH),
    .TX_TAG_WIDTH(TX_TAG_WIDTH),
    .TX_CHECKSUM_ENABLE(TX_CHECKSUM_ENABLE),
    .RX_HASH_ENABLE(RX_HASH_ENABLE),
    .RX_CHECKSUM_ENABLE(RX_CHECKSUM_ENABLE),
    .PFC_ENABLE(PFC_ENABLE),
    .LFC_ENABLE(LFC_ENABLE),
    .ENABLE_PADDING(ENABLE_PADDING),
    .ENABLE_DIC(ENABLE_DIC),
    .MIN_FRAME_LENGTH(MIN_FRAME_LENGTH),
    .TX_FIFO_DEPTH(TX_FIFO_DEPTH),
    .RX_FIFO_DEPTH(RX_FIFO_DEPTH),
    .MAX_TX_SIZE(MAX_TX_SIZE),
    .MAX_RX_SIZE(MAX_RX_SIZE),
    .TX_RAM_SIZE(TX_RAM_SIZE),
    .RX_RAM_SIZE(RX_RAM_SIZE),

    // RAM configuration
    .DDR_CH(DDR_CH),
    .DDR_ENABLE(DDR_ENABLE),
    .AXI_DDR_DATA_WIDTH(AXI_DDR_DATA_WIDTH),
    .AXI_DDR_ADDR_WIDTH(AXI_DDR_ADDR_WIDTH),
    .AXI_DDR_STRB_WIDTH(AXI_DDR_STRB_WIDTH),
    .AXI_DDR_ID_WIDTH(AXI_DDR_ID_WIDTH),
    .AXI_DDR_MAX_BURST_LEN(AXI_DDR_MAX_BURST_LEN),
    .AXI_DDR_NARROW_BURST(AXI_DDR_NARROW_BURST),

    // Application block configuration
    .APP_ID(APP_ID),
    .APP_ENABLE(APP_ENABLE),
    .APP_CTRL_ENABLE(APP_CTRL_ENABLE),
    .APP_DMA_ENABLE(APP_DMA_ENABLE),
    .APP_AXIS_DIRECT_ENABLE(APP_AXIS_DIRECT_ENABLE),
    .APP_AXIS_SYNC_ENABLE(APP_AXIS_SYNC_ENABLE),
    .APP_AXIS_IF_ENABLE(APP_AXIS_IF_ENABLE),
    .APP_STAT_ENABLE(APP_STAT_ENABLE),

    // DMA interface configuration
    .DMA_IMM_ENABLE(DMA_IMM_ENABLE),
    .DMA_IMM_WIDTH(DMA_IMM_WIDTH),
    .DMA_LEN_WIDTH(DMA_LEN_WIDTH),
    .DMA_TAG_WIDTH(DMA_TAG_WIDTH),
    .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
    .RAM_PIPELINE(RAM_PIPELINE),

    // PCIe interface configuration
    .AXIS_PCIE_DATA_WIDTH(AXIS_PCIE_DATA_WIDTH),
    .AXIS_PCIE_KEEP_WIDTH(AXIS_PCIE_KEEP_WIDTH),
    .AXIS_PCIE_RC_USER_WIDTH(AXIS_PCIE_RC_USER_WIDTH),
    .AXIS_PCIE_RQ_USER_WIDTH(AXIS_PCIE_RQ_USER_WIDTH),
    .AXIS_PCIE_CQ_USER_WIDTH(AXIS_PCIE_CQ_USER_WIDTH),
    .AXIS_PCIE_CC_USER_WIDTH(AXIS_PCIE_CC_USER_WIDTH),
    .RC_STRADDLE(RC_STRADDLE),
    .RQ_STRADDLE(RQ_STRADDLE),
    .CQ_STRADDLE(CQ_STRADDLE),
    .CC_STRADDLE(CC_STRADDLE),
    .RQ_SEQ_NUM_WIDTH(RQ_SEQ_NUM_WIDTH),
    .PF_COUNT(PF_COUNT),
    .VF_COUNT(VF_COUNT),
    .PCIE_TAG_COUNT(PCIE_TAG_COUNT),

    // Interrupt configuration
    .IRQ_INDEX_WIDTH(IRQ_INDEX_WIDTH),

    // AXI lite interface configuration (control)
    .AXIL_CTRL_DATA_WIDTH(AXIL_CTRL_DATA_WIDTH),
    .AXIL_CTRL_ADDR_WIDTH(AXIL_CTRL_ADDR_WIDTH),

    // AXI lite interface configuration (application control)
    .AXIL_APP_CTRL_DATA_WIDTH(AXIL_APP_CTRL_DATA_WIDTH),
    .AXIL_APP_CTRL_ADDR_WIDTH(AXIL_APP_CTRL_ADDR_WIDTH),

    // Ethernet interface configuration
    .XGMII_DATA_WIDTH(XGMII_DATA_WIDTH),
    .XGMII_CTRL_WIDTH(XGMII_CTRL_WIDTH),
    .AXIS_ETH_DATA_WIDTH(AXIS_ETH_DATA_WIDTH),
    .AXIS_ETH_KEEP_WIDTH(AXIS_ETH_KEEP_WIDTH),
    .AXIS_ETH_SYNC_DATA_WIDTH(AXIS_ETH_SYNC_DATA_WIDTH),
    .AXIS_ETH_TX_USER_WIDTH(AXIS_ETH_TX_USER_WIDTH),
    .AXIS_ETH_RX_USER_WIDTH(AXIS_ETH_RX_USER_WIDTH),
    .AXIS_ETH_TX_PIPELINE(AXIS_ETH_TX_PIPELINE),
    .AXIS_ETH_TX_FIFO_PIPELINE(AXIS_ETH_TX_FIFO_PIPELINE),
    .AXIS_ETH_TX_TS_PIPELINE(AXIS_ETH_TX_TS_PIPELINE),
    .AXIS_ETH_RX_PIPELINE(AXIS_ETH_RX_PIPELINE),
    .AXIS_ETH_RX_FIFO_PIPELINE(AXIS_ETH_RX_FIFO_PIPELINE),

    // Statistics counter subsystem
    .STAT_ENABLE(STAT_ENABLE),
    .STAT_DMA_ENABLE(STAT_DMA_ENABLE),
    .STAT_PCIE_ENABLE(STAT_PCIE_ENABLE),
    .STAT_INC_WIDTH(STAT_INC_WIDTH),
    .STAT_ID_WIDTH(STAT_ID_WIDTH)
)
core_inst (
    /*
     * Clock: 250 MHz
     * Synchronous reset
     */
    .clk_250mhz(pcie_user_clk),
    .rst_250mhz(pcie_user_reset),

    /*
     * PTP clock
     */
    .ptp_clk(ptp_clk),
    .ptp_rst(ptp_rst),
    .ptp_sample_clk(ptp_sample_clk),

    /*
     * GPIO
     */
    .led_red(led_red),
    //.led_green(led_green),
    .led_bmc(led_bmc),
    .led_exp(led_exp),

    .pps_in(pps_in),
    .pps_out(pps_out),
    .pps_out_en(pps_out_en),

    /*
     * BMC interface
     */
    .bmc_clk(bmc_clk),
    .bmc_nss(bmc_nss),
    .bmc_mosi(bmc_mosi),
    .bmc_miso(bmc_miso),
    .bmc_int(bmc_int),

    /*
     * PCIe
     */
    .m_axis_rq_tdata(axis_rq_tdata),
    .m_axis_rq_tkeep(axis_rq_tkeep),
    .m_axis_rq_tlast(axis_rq_tlast),
    .m_axis_rq_tready(axis_rq_tready),
    .m_axis_rq_tuser(axis_rq_tuser),
    .m_axis_rq_tvalid(axis_rq_tvalid),

    .s_axis_rc_tdata(axis_rc_tdata),
    .s_axis_rc_tkeep(axis_rc_tkeep),
    .s_axis_rc_tlast(axis_rc_tlast),
    .s_axis_rc_tready(axis_rc_tready),
    .s_axis_rc_tuser(axis_rc_tuser),
    .s_axis_rc_tvalid(axis_rc_tvalid),

    .s_axis_cq_tdata(axis_cq_tdata),
    .s_axis_cq_tkeep(axis_cq_tkeep),
    .s_axis_cq_tlast(axis_cq_tlast),
    .s_axis_cq_tready(axis_cq_tready),
    .s_axis_cq_tuser(axis_cq_tuser),
    .s_axis_cq_tvalid(axis_cq_tvalid),

    .m_axis_cc_tdata(axis_cc_tdata),
    .m_axis_cc_tkeep(axis_cc_tkeep),
    .m_axis_cc_tlast(axis_cc_tlast),
    .m_axis_cc_tready(axis_cc_tready),
    .m_axis_cc_tuser(axis_cc_tuser),
    .m_axis_cc_tvalid(axis_cc_tvalid),

    .s_axis_rq_seq_num_0(pcie_rq_seq_num0),
    .s_axis_rq_seq_num_valid_0(pcie_rq_seq_num_vld0),
    .s_axis_rq_seq_num_1(pcie_rq_seq_num1),
    .s_axis_rq_seq_num_valid_1(pcie_rq_seq_num_vld1),

    .pcie_tfc_nph_av(pcie_tfc_nph_av),
    .pcie_tfc_npd_av(pcie_tfc_npd_av),

    .cfg_max_payload(cfg_max_payload),
    .cfg_max_read_req(cfg_max_read_req),
    .cfg_rcb_status(cfg_rcb_status),

    .cfg_mgmt_addr(cfg_mgmt_addr),
    .cfg_mgmt_function_number(cfg_mgmt_function_number),
    .cfg_mgmt_write(cfg_mgmt_write),
    .cfg_mgmt_write_data(cfg_mgmt_write_data),
    .cfg_mgmt_byte_enable(cfg_mgmt_byte_enable),
    .cfg_mgmt_read(cfg_mgmt_read),
    .cfg_mgmt_read_data(cfg_mgmt_read_data),
    .cfg_mgmt_read_write_done(cfg_mgmt_read_write_done),

    .cfg_fc_ph(cfg_fc_ph),
    .cfg_fc_pd(cfg_fc_pd),
    .cfg_fc_nph(cfg_fc_nph),
    .cfg_fc_npd(cfg_fc_npd),
    .cfg_fc_cplh(cfg_fc_cplh),
    .cfg_fc_cpld(cfg_fc_cpld),
    .cfg_fc_sel(cfg_fc_sel),

    .cfg_interrupt_msix_enable(cfg_interrupt_msix_enable),
    .cfg_interrupt_msix_mask(cfg_interrupt_msix_mask),
    .cfg_interrupt_msix_vf_enable(cfg_interrupt_msix_vf_enable),
    .cfg_interrupt_msix_vf_mask(cfg_interrupt_msix_vf_mask),
    .cfg_interrupt_msix_address(cfg_interrupt_msix_address),
    .cfg_interrupt_msix_data(cfg_interrupt_msix_data),
    .cfg_interrupt_msix_int(cfg_interrupt_msix_int),
    .cfg_interrupt_msix_vec_pending(cfg_interrupt_msix_vec_pending),
    .cfg_interrupt_msix_vec_pending_status(cfg_interrupt_msix_vec_pending_status),
    .cfg_interrupt_msix_sent(cfg_interrupt_msix_sent),
    .cfg_interrupt_msix_fail(cfg_interrupt_msix_fail),
    .cfg_interrupt_msi_function_number(cfg_interrupt_msi_function_number),

    .status_error_cor(status_error_cor),
    .status_error_uncor(status_error_uncor),

    /*
     * Ethernet: QSFP28
     */
    .qsfp_0_tx_clk_0(qsfp_0_tx_clk_0_int),
    .qsfp_0_tx_rst_0(qsfp_0_tx_rst_0_int),
    .qsfp_0_txd_0(qsfp_0_txd_0_int),
    .qsfp_0_txc_0(qsfp_0_txc_0_int),
    .qsfp_0_cfg_tx_prbs31_enable_0(qsfp_0_cfg_tx_prbs31_enable_0_int),
    .qsfp_0_rx_clk_0(qsfp_0_rx_clk_0_int),
    .qsfp_0_rx_rst_0(qsfp_0_rx_rst_0_int),
    .qsfp_0_rxd_0(qsfp_0_rxd_0_int),
    .qsfp_0_rxc_0(qsfp_0_rxc_0_int),
    .qsfp_0_cfg_rx_prbs31_enable_0(qsfp_0_cfg_rx_prbs31_enable_0_int),
    .qsfp_0_rx_error_count_0(qsfp_0_rx_error_count_0_int),
    .qsfp_0_rx_status_0(qsfp_0_rx_status_0),

    .qsfp_0_tx_clk_1(qsfp_0_tx_clk_1_int),
    .qsfp_0_tx_rst_1(qsfp_0_tx_rst_1_int),
    .qsfp_0_txd_1(qsfp_0_txd_1_int),
    .qsfp_0_txc_1(qsfp_0_txc_1_int),
    .qsfp_0_cfg_tx_prbs31_enable_1(qsfp_0_cfg_tx_prbs31_enable_1_int),
    .qsfp_0_rx_clk_1(qsfp_0_rx_clk_1_int),
    .qsfp_0_rx_rst_1(qsfp_0_rx_rst_1_int),
    .qsfp_0_rxd_1(qsfp_0_rxd_1_int),
    .qsfp_0_rxc_1(qsfp_0_rxc_1_int),
    .qsfp_0_cfg_rx_prbs31_enable_1(qsfp_0_cfg_rx_prbs31_enable_1_int),
    .qsfp_0_rx_error_count_1(qsfp_0_rx_error_count_1_int),
    .qsfp_0_rx_status_1(qsfp_0_rx_status_1),

    .qsfp_0_tx_clk_2(qsfp_0_tx_clk_2_int),
    .qsfp_0_tx_rst_2(qsfp_0_tx_rst_2_int),
    .qsfp_0_txd_2(qsfp_0_txd_2_int),
    .qsfp_0_txc_2(qsfp_0_txc_2_int),
    .qsfp_0_cfg_tx_prbs31_enable_2(qsfp_0_cfg_tx_prbs31_enable_2_int),
    .qsfp_0_rx_clk_2(qsfp_0_rx_clk_2_int),
    .qsfp_0_rx_rst_2(qsfp_0_rx_rst_2_int),
    .qsfp_0_rxd_2(qsfp_0_rxd_2_int),
    .qsfp_0_rxc_2(qsfp_0_rxc_2_int),
    .qsfp_0_cfg_rx_prbs31_enable_2(qsfp_0_cfg_rx_prbs31_enable_2_int),
    .qsfp_0_rx_error_count_2(qsfp_0_rx_error_count_2_int),
    .qsfp_0_rx_status_2(qsfp_0_rx_status_2),

    .qsfp_0_tx_clk_3(qsfp_0_tx_clk_3_int),
    .qsfp_0_tx_rst_3(qsfp_0_tx_rst_3_int),
    .qsfp_0_txd_3(qsfp_0_txd_3_int),
    .qsfp_0_txc_3(qsfp_0_txc_3_int),
    .qsfp_0_cfg_tx_prbs31_enable_3(qsfp_0_cfg_tx_prbs31_enable_3_int),
    .qsfp_0_rx_clk_3(qsfp_0_rx_clk_3_int),
    .qsfp_0_rx_rst_3(qsfp_0_rx_rst_3_int),
    .qsfp_0_rxd_3(qsfp_0_rxd_3_int),
    .qsfp_0_rxc_3(qsfp_0_rxc_3_int),
    .qsfp_0_cfg_rx_prbs31_enable_3(qsfp_0_cfg_rx_prbs31_enable_3_int),
    .qsfp_0_rx_error_count_3(qsfp_0_rx_error_count_3_int),
    .qsfp_0_rx_status_3(qsfp_0_rx_status_3),

    .qsfp_0_drp_clk(qsfp_0_drp_clk),
    .qsfp_0_drp_rst(qsfp_0_drp_rst),
    .qsfp_0_drp_addr(qsfp_0_drp_addr),
    .qsfp_0_drp_di(qsfp_0_drp_di),
    .qsfp_0_drp_en(qsfp_0_drp_en),
    .qsfp_0_drp_we(qsfp_0_drp_we),
    .qsfp_0_drp_do(qsfp_0_drp_do),
    .qsfp_0_drp_rdy(qsfp_0_drp_rdy),

    .qsfp_0_mod_prsnt_n(qsfp_0_mod_prsnt_n_int),
    .qsfp_0_reset_n(qsfp_0_reset_n),
    .qsfp_0_lp_mode(qsfp_0_lp_mode),
    .qsfp_0_intr_n(qsfp_0_intr_n_int),

    .qsfp_0_i2c_scl_i(qsfp_0_i2c_scl_i),
    .qsfp_0_i2c_scl_o(qsfp_0_i2c_scl_o),
    .qsfp_0_i2c_scl_t(qsfp_0_i2c_scl_t),
    .qsfp_0_i2c_sda_i(qsfp_0_i2c_sda_i),
    .qsfp_0_i2c_sda_o(qsfp_0_i2c_sda_o),
    .qsfp_0_i2c_sda_t(qsfp_0_i2c_sda_t),

    .qsfp_1_tx_clk_0(qsfp_1_tx_clk_0_int),
    .qsfp_1_tx_rst_0(qsfp_1_tx_rst_0_int),
    .qsfp_1_txd_0(qsfp_1_txd_0_int),
    .qsfp_1_txc_0(qsfp_1_txc_0_int),
    .qsfp_1_cfg_tx_prbs31_enable_0(qsfp_1_cfg_tx_prbs31_enable_0_int),
    .qsfp_1_rx_clk_0(qsfp_1_rx_clk_0_int),
    .qsfp_1_rx_rst_0(qsfp_1_rx_rst_0_int),
    .qsfp_1_rxd_0(qsfp_1_rxd_0_int),
    .qsfp_1_rxc_0(qsfp_1_rxc_0_int),
    .qsfp_1_cfg_rx_prbs31_enable_0(qsfp_1_cfg_rx_prbs31_enable_0_int),
    .qsfp_1_rx_error_count_0(qsfp_1_rx_error_count_0_int),
    .qsfp_1_rx_status_0(qsfp_1_rx_status_0),

    .qsfp_1_tx_clk_1(qsfp_1_tx_clk_1_int),
    .qsfp_1_tx_rst_1(qsfp_1_tx_rst_1_int),
    .qsfp_1_txd_1(qsfp_1_txd_1_int),
    .qsfp_1_txc_1(qsfp_1_txc_1_int),
    .qsfp_1_cfg_tx_prbs31_enable_1(qsfp_1_cfg_tx_prbs31_enable_1_int),
    .qsfp_1_rx_clk_1(qsfp_1_rx_clk_1_int),
    .qsfp_1_rx_rst_1(qsfp_1_rx_rst_1_int),
    .qsfp_1_rxd_1(qsfp_1_rxd_1_int),
    .qsfp_1_rxc_1(qsfp_1_rxc_1_int),
    .qsfp_1_cfg_rx_prbs31_enable_1(qsfp_1_cfg_rx_prbs31_enable_1_int),
    .qsfp_1_rx_error_count_1(qsfp_1_rx_error_count_1_int),
    .qsfp_1_rx_status_1(qsfp_1_rx_status_1),

    .qsfp_1_tx_clk_2(qsfp_1_tx_clk_2_int),
    .qsfp_1_tx_rst_2(qsfp_1_tx_rst_2_int),
    .qsfp_1_txd_2(qsfp_1_txd_2_int),
    .qsfp_1_txc_2(qsfp_1_txc_2_int),
    .qsfp_1_cfg_tx_prbs31_enable_2(qsfp_1_cfg_tx_prbs31_enable_2_int),
    .qsfp_1_rx_clk_2(qsfp_1_rx_clk_2_int),
    .qsfp_1_rx_rst_2(qsfp_1_rx_rst_2_int),
    .qsfp_1_rxd_2(qsfp_1_rxd_2_int),
    .qsfp_1_rxc_2(qsfp_1_rxc_2_int),
    .qsfp_1_cfg_rx_prbs31_enable_2(qsfp_1_cfg_rx_prbs31_enable_2_int),
    .qsfp_1_rx_error_count_2(qsfp_1_rx_error_count_2_int),
    .qsfp_1_rx_status_2(qsfp_1_rx_status_2),

    .qsfp_1_tx_clk_3(qsfp_1_tx_clk_3_int),
    .qsfp_1_tx_rst_3(qsfp_1_tx_rst_3_int),
    .qsfp_1_txd_3(qsfp_1_txd_3_int),
    .qsfp_1_txc_3(qsfp_1_txc_3_int),
    .qsfp_1_cfg_tx_prbs31_enable_3(qsfp_1_cfg_tx_prbs31_enable_3_int),
    .qsfp_1_rx_clk_3(qsfp_1_rx_clk_3_int),
    .qsfp_1_rx_rst_3(qsfp_1_rx_rst_3_int),
    .qsfp_1_rxd_3(qsfp_1_rxd_3_int),
    .qsfp_1_rxc_3(qsfp_1_rxc_3_int),
    .qsfp_1_cfg_rx_prbs31_enable_3(qsfp_1_cfg_rx_prbs31_enable_3_int),
    .qsfp_1_rx_error_count_3(qsfp_1_rx_error_count_3_int),
    .qsfp_1_rx_status_3(qsfp_1_rx_status_3),

    .qsfp_1_drp_clk(qsfp_1_drp_clk),
    .qsfp_1_drp_rst(qsfp_1_drp_rst),
    .qsfp_1_drp_addr(qsfp_1_drp_addr),
    .qsfp_1_drp_di(qsfp_1_drp_di),
    .qsfp_1_drp_en(qsfp_1_drp_en),
    .qsfp_1_drp_we(qsfp_1_drp_we),
    .qsfp_1_drp_do(qsfp_1_drp_do),
    .qsfp_1_drp_rdy(qsfp_1_drp_rdy),

    .qsfp_1_mod_prsnt_n(qsfp_1_mod_prsnt_n_int),
    .qsfp_1_reset_n(qsfp_1_reset_n),
    .qsfp_1_lp_mode(qsfp_1_lp_mode),
    .qsfp_1_intr_n(qsfp_1_intr_n_int),

    .qsfp_1_i2c_scl_i(qsfp_1_i2c_scl_i),
    .qsfp_1_i2c_scl_o(qsfp_1_i2c_scl_o),
    .qsfp_1_i2c_scl_t(qsfp_1_i2c_scl_t),
    .qsfp_1_i2c_sda_i(qsfp_1_i2c_sda_i),
    .qsfp_1_i2c_sda_o(qsfp_1_i2c_sda_o),
    .qsfp_1_i2c_sda_t(qsfp_1_i2c_sda_t),

    /*
     * DDR
     */
    .ddr_clk(ddr_clk),
    .ddr_rst(ddr_rst),

    .m_axi_ddr_awid(m_axi_ddr_awid),
    .m_axi_ddr_awaddr(m_axi_ddr_awaddr),
    .m_axi_ddr_awlen(m_axi_ddr_awlen),
    .m_axi_ddr_awsize(m_axi_ddr_awsize),
    .m_axi_ddr_awburst(m_axi_ddr_awburst),
    .m_axi_ddr_awlock(m_axi_ddr_awlock),
    .m_axi_ddr_awcache(m_axi_ddr_awcache),
    .m_axi_ddr_awprot(m_axi_ddr_awprot),
    .m_axi_ddr_awqos(m_axi_ddr_awqos),
    .m_axi_ddr_awvalid(m_axi_ddr_awvalid),
    .m_axi_ddr_awready(m_axi_ddr_awready),
    .m_axi_ddr_wdata(m_axi_ddr_wdata),
    .m_axi_ddr_wstrb(m_axi_ddr_wstrb),
    .m_axi_ddr_wlast(m_axi_ddr_wlast),
    .m_axi_ddr_wvalid(m_axi_ddr_wvalid),
    .m_axi_ddr_wready(m_axi_ddr_wready),
    .m_axi_ddr_bid(m_axi_ddr_bid),
    .m_axi_ddr_bresp(m_axi_ddr_bresp),
    .m_axi_ddr_bvalid(m_axi_ddr_bvalid),
    .m_axi_ddr_bready(m_axi_ddr_bready),
    .m_axi_ddr_arid(m_axi_ddr_arid),
    .m_axi_ddr_araddr(m_axi_ddr_araddr),
    .m_axi_ddr_arlen(m_axi_ddr_arlen),
    .m_axi_ddr_arsize(m_axi_ddr_arsize),
    .m_axi_ddr_arburst(m_axi_ddr_arburst),
    .m_axi_ddr_arlock(m_axi_ddr_arlock),
    .m_axi_ddr_arcache(m_axi_ddr_arcache),
    .m_axi_ddr_arprot(m_axi_ddr_arprot),
    .m_axi_ddr_arqos(m_axi_ddr_arqos),
    .m_axi_ddr_arvalid(m_axi_ddr_arvalid),
    .m_axi_ddr_arready(m_axi_ddr_arready),
    .m_axi_ddr_rid(m_axi_ddr_rid),
    .m_axi_ddr_rdata(m_axi_ddr_rdata),
    .m_axi_ddr_rresp(m_axi_ddr_rresp),
    .m_axi_ddr_rlast(m_axi_ddr_rlast),
    .m_axi_ddr_rvalid(m_axi_ddr_rvalid),
    .m_axi_ddr_rready(m_axi_ddr_rready),

    .ddr_status(ddr_status),

    /*
     * QSPI flash
     */
    .fpga_boot(fpga_boot),
    .qspi_clk(qspi_clk_int),
    .qspi_dq_i(qspi_dq_i_int),
    .qspi_dq_o(qspi_dq_o_int),
    .qspi_dq_oe(qspi_dq_oe_int),
    .qspi_cs(qspi_cs_int)
);

endmodule

`resetall
