// SPDX-License-Identifier: BSD-2-Clause-Views
/*
 * Copyright (c) 2023 The Regents of the University of California
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
    parameter FPGA_ID = 32'h4341A0DD,
    parameter FW_ID = 32'h00000000,
    parameter FW_VER = 32'h00_00_01_00,
    parameter BOARD_ID = 32'h12ba_b5d4,
    parameter BOARD_VER = 32'h01_00_00_00,
    parameter BUILD_DATE = 32'd1563227611,
    parameter GIT_HASH = 32'hdce357bf,
    parameter RELEASE_INFO = 32'h00000000,

    // Board configuration
    parameter MAC_100G = 1,
    parameter MAC_RSFEC = 1,

    // Structural configuration
    parameter IF_COUNT = 1,
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
    parameter TX_QUEUE_INDEX_WIDTH = 10,
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
    parameter TX_FIFO_DEPTH = 32768,
    parameter RX_FIFO_DEPTH = 131072,
    parameter MAX_TX_SIZE = 9214,
    parameter MAX_RX_SIZE = 9214,
    parameter TX_RAM_SIZE = 131072,
    parameter RX_RAM_SIZE = 131072,

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
    parameter SEG_COUNT = 2,
    parameter SEG_DATA_WIDTH = 256,
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
    parameter AXIS_ETH_SYNC_DATA_WIDTH_DOUBLE = MAC_100G ? 0 : (MAC_RSFEC ? 1 : 0),
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
     * Clock: 100 MHz
     * Reset: Push button, active low
     */
    // input  wire         usr_clk_33m,
    input  wire         sys_clk_50m,

    /*
     * GPIO
     */
    output wire         user_led_g,
    output wire         user_led_r,

    /*
     * I2C
     */
    inout  wire         fpga_i2c_scl,
    inout  wire         fpga_i2c_sda,
    output wire         fpga_i2c_req_l,
    input  wire         fpga_i2c_mux_gnt,

    /*
     * PCIe: gen 4 x16
     */
    output wire [15:0]  pcie_tx_p,
    output wire [15:0]  pcie_tx_n,
    input  wire [15:0]  pcie_rx_p,
    input  wire [15:0]  pcie_rx_n,
    input  wire [1:0]   pcie_refclk_p,
    input  wire         pcie_perst_n,

    /*
     * Ethernet: QSFP-DD
     */
    output wire [7:0]   qsfp_tx_p,
    // output wire [7:0]   qsfp_tx_n,
    input  wire [7:0]   qsfp_rx_p,
    // input  wire [7:0]   qsfp_rx_n,
    input  wire         qsfp_refclk_156m_p
);

// PTP configuration
parameter PTP_CLK_PERIOD_NS_NUM = 2048;
parameter PTP_CLK_PERIOD_NS_DENOM = 825;
parameter PTP_TS_WIDTH = 96;
parameter PTP_TAG_WIDTH = 8;

// Interface configuration
parameter TX_TAG_WIDTH = PTP_TAG_WIDTH;

// PCIe interface configuration
parameter SEG_EMPTY_WIDTH = $clog2(SEG_DATA_WIDTH/32);
parameter SEG_HDR_WIDTH = 128;
parameter SEG_PRFX_WIDTH = 32;
parameter TX_SEQ_NUM_WIDTH = 6;
parameter PCIE_TAG_COUNT = 256;

// Ethernet interface configuration
parameter AXIS_ETH_DATA_WIDTH = MAC_100G ? 512 : 64;
parameter AXIS_ETH_KEEP_WIDTH = AXIS_ETH_DATA_WIDTH/8;
parameter AXIS_ETH_SYNC_DATA_WIDTH = AXIS_ETH_DATA_WIDTH*(AXIS_ETH_SYNC_DATA_WIDTH_DOUBLE && !MAC_100G ? 2 : 1);
parameter AXIS_ETH_TX_USER_WIDTH = TX_TAG_WIDTH + 1;
parameter AXIS_ETH_RX_USER_WIDTH = (PTP_TS_ENABLE ? PTP_TS_WIDTH : 0) + 1;

// Clock and reset
wire ninit_done;

wire pcie_clk;
wire pcie_rst;

reset_release reset_release_inst (
    .ninit_done (ninit_done)
);

wire clk_50mhz = sys_clk_50m;
wire rst_50mhz;

sync_reset #(
    .N(20)
)
sync_reset_50mhz_inst (
    .clk(clk_50mhz),
    .rst(pcie_rst),
    .out(rst_50mhz)
);

// GPIO
wire fpga_i2c_scl_i;
wire fpga_i2c_scl_o;
wire fpga_i2c_scl_t;
wire fpga_i2c_sda_i;
wire fpga_i2c_sda_o;
wire fpga_i2c_sda_t;
wire fpga_i2c_req_l_int;
wire fpga_i2c_mux_gnt_int;

reg fpga_i2c_scl_o_reg;
reg fpga_i2c_scl_t_reg;
reg fpga_i2c_sda_o_reg;
reg fpga_i2c_sda_t_reg;
reg fpga_i2c_req_l_reg;

always @(posedge pcie_clk) begin
    fpga_i2c_scl_o_reg <= fpga_i2c_scl_o;
    fpga_i2c_scl_t_reg <= fpga_i2c_scl_t;
    fpga_i2c_sda_o_reg <= fpga_i2c_sda_o;
    fpga_i2c_sda_t_reg <= fpga_i2c_sda_t;
    fpga_i2c_req_l_reg <= fpga_i2c_req_l_int;
end

sync_signal #(
    .WIDTH(3),
    .N(2)
)
sync_signal_inst (
    .clk(pcie_clk),
    .in({fpga_i2c_scl, fpga_i2c_sda, fpga_i2c_mux_gnt}),
    .out({fpga_i2c_scl_i, fpga_i2c_sda_i, fpga_i2c_mux_gnt_int})
);

assign fpga_i2c_scl = fpga_i2c_scl_t_reg ? 1'bz : fpga_i2c_scl_o_reg;
assign fpga_i2c_sda = fpga_i2c_sda_t_reg ? 1'bz : fpga_i2c_sda_o_reg;
assign fpga_i2c_req_l = fpga_i2c_req_l_reg;

// PCIe
wire coreclkout_hip;
wire reset_status_n;

wire [SEG_COUNT*SEG_DATA_WIDTH-1:0]   rx_st_data;
wire [SEG_COUNT*SEG_EMPTY_WIDTH-1:0]  rx_st_empty;
wire [SEG_COUNT-1:0]                  rx_st_sop;
wire [SEG_COUNT-1:0]                  rx_st_eop;
wire [SEG_COUNT-1:0]                  rx_st_valid;
wire                                  rx_st_ready;
wire [SEG_COUNT*SEG_HDR_WIDTH-1:0]    rx_st_hdr;
wire [SEG_COUNT*SEG_PRFX_WIDTH-1:0]   rx_st_tlp_prfx;
wire [SEG_COUNT-1:0]                  rx_st_vf_active = 0;
wire [SEG_COUNT*3-1:0]                rx_st_func_num = 0;
wire [SEG_COUNT*11-1:0]               rx_st_vf_num = 0;
wire [SEG_COUNT*3-1:0]                rx_st_bar_range;
wire [SEG_COUNT-1:0]                  rx_st_tlp_abort;

wire [SEG_COUNT*SEG_DATA_WIDTH-1:0]   tx_st_data;
wire [SEG_COUNT-1:0]                  tx_st_sop;
wire [SEG_COUNT-1:0]                  tx_st_eop;
wire [SEG_COUNT-1:0]                  tx_st_valid;
wire                                  tx_st_ready;
wire [SEG_COUNT-1:0]                  tx_st_err;
wire [SEG_COUNT*SEG_HDR_WIDTH-1:0]    tx_st_hdr;
wire [SEG_COUNT*SEG_PRFX_WIDTH-1:0]   tx_st_tlp_prfx;

wire [11:0]                           rx_buffer_limit;
wire [1:0]                            rx_buffer_limit_tdm_idx;

wire [15:0]                           tx_cdts_limit;
wire [2:0]                            tx_cdts_limit_tdm_idx;

wire [15:0]                           tl_cfg_ctl;
wire [4:0]                            tl_cfg_add;
wire [2:0]                            tl_cfg_func;

assign pcie_clk = coreclkout_hip;
assign pcie_rst = !reset_status_n;

pcie pcie_hip_inst (
    .p0_rx_st_ready_i(rx_st_ready),
    .p0_rx_st_sop_o(rx_st_sop),
    .p0_rx_st_eop_o(rx_st_eop),
    .p0_rx_st_data_o(rx_st_data),
    .p0_rx_st_valid_o(rx_st_valid),
    .p0_rx_st_empty_o(rx_st_empty),
    .p0_rx_st_hdr_o(rx_st_hdr),
    .p0_rx_st_tlp_prfx_o(rx_st_tlp_prfx),
    .p0_rx_st_bar_range_o(rx_st_bar_range),
    .p0_rx_st_tlp_abort_o(rx_st_tlp_abort),
    .p0_rx_par_err_o(),
    .p0_tx_st_sop_i(tx_st_sop),
    .p0_tx_st_eop_i(tx_st_eop),
    .p0_tx_st_data_i(tx_st_data),
    .p0_tx_st_valid_i(tx_st_valid),
    .p0_tx_st_err_i(tx_st_err),
    .p0_tx_st_ready_o(tx_st_ready),
    .p0_tx_st_hdr_i(tx_st_hdr),
    .p0_tx_st_tlp_prfx_i(tx_st_tlp_prfx),
    .p0_tx_par_err_o(),
    .p0_tx_cdts_limit_o(tx_cdts_limit),
    .p0_tx_cdts_limit_tdm_idx_o(tx_cdts_limit_tdm_idx),
    .p0_tl_cfg_func_o(tl_cfg_func),
    .p0_tl_cfg_add_o(tl_cfg_add),
    .p0_tl_cfg_ctl_o(tl_cfg_ctl),
    .p0_dl_timer_update_o(),
    .p0_reset_status_n(reset_status_n),
    .p0_pin_perst_n(),
    .p0_link_up_o(),
    .p0_dl_up_o(),
    .p0_surprise_down_err_o(),
    .p0_ltssm_state_o(),
    .rx_n_in0(pcie_rx_n[0]),
    .rx_n_in1(pcie_rx_n[1]),
    .rx_n_in2(pcie_rx_n[2]),
    .rx_n_in3(pcie_rx_n[3]),
    .rx_n_in4(pcie_rx_n[4]),
    .rx_n_in5(pcie_rx_n[5]),
    .rx_n_in6(pcie_rx_n[6]),
    .rx_n_in7(pcie_rx_n[7]),
    .rx_n_in8(pcie_rx_n[8]),
    .rx_n_in9(pcie_rx_n[9]),
    .rx_n_in10(pcie_rx_n[10]),
    .rx_n_in11(pcie_rx_n[11]),
    .rx_n_in12(pcie_rx_n[12]),
    .rx_n_in13(pcie_rx_n[13]),
    .rx_n_in14(pcie_rx_n[14]),
    .rx_n_in15(pcie_rx_n[15]),
    .rx_p_in0(pcie_rx_p[0]),
    .rx_p_in1(pcie_rx_p[1]),
    .rx_p_in2(pcie_rx_p[2]),
    .rx_p_in3(pcie_rx_p[3]),
    .rx_p_in4(pcie_rx_p[4]),
    .rx_p_in5(pcie_rx_p[5]),
    .rx_p_in6(pcie_rx_p[6]),
    .rx_p_in7(pcie_rx_p[7]),
    .rx_p_in8(pcie_rx_p[8]),
    .rx_p_in9(pcie_rx_p[9]),
    .rx_p_in10(pcie_rx_p[10]),
    .rx_p_in11(pcie_rx_p[11]),
    .rx_p_in12(pcie_rx_p[12]),
    .rx_p_in13(pcie_rx_p[13]),
    .rx_p_in14(pcie_rx_p[14]),
    .rx_p_in15(pcie_rx_p[15]),
    .tx_n_out0(pcie_tx_n[0]),
    .tx_n_out1(pcie_tx_n[1]),
    .tx_n_out2(pcie_tx_n[2]),
    .tx_n_out3(pcie_tx_n[3]),
    .tx_n_out4(pcie_tx_n[4]),
    .tx_n_out5(pcie_tx_n[5]),
    .tx_n_out6(pcie_tx_n[6]),
    .tx_n_out7(pcie_tx_n[7]),
    .tx_n_out8(pcie_tx_n[8]),
    .tx_n_out9(pcie_tx_n[9]),
    .tx_n_out10(pcie_tx_n[10]),
    .tx_n_out11(pcie_tx_n[11]),
    .tx_n_out12(pcie_tx_n[12]),
    .tx_n_out13(pcie_tx_n[13]),
    .tx_n_out14(pcie_tx_n[14]),
    .tx_n_out15(pcie_tx_n[15]),
    .tx_p_out0(pcie_tx_p[0]),
    .tx_p_out1(pcie_tx_p[1]),
    .tx_p_out2(pcie_tx_p[2]),
    .tx_p_out3(pcie_tx_p[3]),
    .tx_p_out4(pcie_tx_p[4]),
    .tx_p_out5(pcie_tx_p[5]),
    .tx_p_out6(pcie_tx_p[6]),
    .tx_p_out7(pcie_tx_p[7]),
    .tx_p_out8(pcie_tx_p[8]),
    .tx_p_out9(pcie_tx_p[9]),
    .tx_p_out10(pcie_tx_p[10]),
    .tx_p_out11(pcie_tx_p[11]),
    .tx_p_out12(pcie_tx_p[12]),
    .tx_p_out13(pcie_tx_p[13]),
    .tx_p_out14(pcie_tx_p[14]),
    .tx_p_out15(pcie_tx_p[15]),
    .coreclkout_hip(coreclkout_hip),
    .refclk0(pcie_refclk_p[0]),
    .refclk1(pcie_refclk_p[1]),
    .pin_perst_n(pcie_perst_n),
    .ninit_done(ninit_done)
);

// QSFP-DD interfaces
localparam QSFP_CNT = 1;
localparam CH_CNT = MAC_100G ? QSFP_CNT*2 : QSFP_CNT*8;

wire [CH_CNT-1:0]                         qsfp_mac_tx_clk;
wire [CH_CNT-1:0]                         qsfp_mac_tx_rst;

wire [CH_CNT*AXIS_ETH_DATA_WIDTH-1:0]     qsfp_mac_tx_axis_tdata;
wire [CH_CNT*AXIS_ETH_KEEP_WIDTH-1:0]     qsfp_mac_tx_axis_tkeep;
wire [CH_CNT-1:0]                         qsfp_mac_tx_axis_tvalid;
wire [CH_CNT-1:0]                         qsfp_mac_tx_axis_tready;
wire [CH_CNT-1:0]                         qsfp_mac_tx_axis_tlast;
wire [CH_CNT*AXIS_ETH_TX_USER_WIDTH-1:0]  qsfp_mac_tx_axis_tuser;

wire [CH_CNT-1:0]                         qsfp_mac_tx_ptp_clk;
wire [CH_CNT-1:0]                         qsfp_mac_tx_ptp_rst;
wire [CH_CNT*PTP_TS_WIDTH-1:0]            qsfp_mac_tx_ptp_time;

wire [CH_CNT*PTP_TS_WIDTH-1:0]            qsfp_mac_tx_ptp_ts;
wire [CH_CNT*TX_TAG_WIDTH-1:0]            qsfp_mac_tx_ptp_ts_tag;
wire [CH_CNT-1:0]                         qsfp_mac_tx_ptp_ts_valid;

wire [CH_CNT-1:0]                         qsfp_mac_tx_status;
wire [CH_CNT-1:0]                         qsfp_mac_tx_lfc_req;
wire [CH_CNT*8-1:0]                       qsfp_mac_tx_pfc_req;

wire [CH_CNT-1:0]                         qsfp_mac_rx_clk;
wire [CH_CNT-1:0]                         qsfp_mac_rx_rst;

wire [CH_CNT*AXIS_ETH_DATA_WIDTH-1:0]     qsfp_mac_rx_axis_tdata;
wire [CH_CNT*AXIS_ETH_KEEP_WIDTH-1:0]     qsfp_mac_rx_axis_tkeep;
wire [CH_CNT-1:0]                         qsfp_mac_rx_axis_tvalid;
wire [CH_CNT-1:0]                         qsfp_mac_rx_axis_tlast;
wire [CH_CNT*AXIS_ETH_RX_USER_WIDTH-1:0]  qsfp_mac_rx_axis_tuser;

wire [CH_CNT-1:0]                         qsfp_mac_rx_ptp_clk;
wire [CH_CNT-1:0]                         qsfp_mac_rx_ptp_rst;
wire [CH_CNT*PTP_TS_WIDTH-1:0]            qsfp_mac_rx_ptp_time;

wire [CH_CNT-1:0]                         qsfp_mac_rx_status;
wire [CH_CNT-1:0]                         qsfp_mac_rx_lfc_req;
wire [CH_CNT*8-1:0]                       qsfp_mac_rx_pfc_req;

generate

if (MAC_100G) begin

    // QSFP-DD
    assign qsfp_mac_tx_ptp_clk[0*2 +: 2] = qsfp_mac_tx_clk[0*2 +: 2];
    assign qsfp_mac_tx_ptp_rst[0*2 +: 2] = qsfp_mac_tx_rst[0*2 +: 2];
    assign qsfp_mac_rx_clk[0*2 +: 2] = qsfp_mac_tx_clk[0*2 +: 2];
    assign qsfp_mac_rx_rst[0*2 +: 2] = qsfp_mac_tx_rst[0*2 +: 2];
    assign qsfp_mac_rx_ptp_clk[0*2 +: 2] = qsfp_mac_tx_clk[0*2 +: 2];
    assign qsfp_mac_rx_ptp_rst[0*2 +: 2] = qsfp_mac_tx_rst[0*2 +: 2];

    eth_mac_dual_wrapper #(
        .PTP_TS_WIDTH(PTP_TS_WIDTH),
        .PTP_TAG_WIDTH(PTP_TAG_WIDTH),
        .DATA_WIDTH(AXIS_ETH_DATA_WIDTH),
        .KEEP_WIDTH(AXIS_ETH_KEEP_WIDTH),
        .TX_USER_WIDTH(AXIS_ETH_TX_USER_WIDTH),
        .RX_USER_WIDTH(AXIS_ETH_RX_USER_WIDTH)
    )
    qsfp_mac_inst (
        .ctrl_clk(clk_50mhz),
        .ctrl_rst(rst_50mhz),

        .tx_serial_data_p({qsfp_tx_p[7], qsfp_tx_p[5], qsfp_tx_p[6], qsfp_tx_p[4], qsfp_tx_p[3], qsfp_tx_p[1], qsfp_tx_p[2], qsfp_tx_p[0]}),
        // .tx_serial_data_n({qsfp_tx_n[7], qsfp_tx_n[5], qsfp_tx_n[6], qsfp_tx_n[4], qsfp_tx_n[3], qsfp_tx_n[1], qsfp_tx_n[2], qsfp_tx_n[0]}),
        .rx_serial_data_p({qsfp_rx_p[7], qsfp_rx_p[5], qsfp_rx_p[6], qsfp_rx_p[4], qsfp_rx_p[3], qsfp_rx_p[1], qsfp_rx_p[2], qsfp_rx_p[0]}),
        // .rx_serial_data_n({qsfp_rx_n[7], qsfp_rx_n[5], qsfp_rx_n[6], qsfp_rx_n[4], qsfp_rx_n[3], qsfp_rx_n[1], qsfp_rx_n[2], qsfp_rx_n[0]}),
        .ref_clk(qsfp_refclk_156m_p),

        .mac_clk(qsfp_mac_tx_clk[0*2 +: 2*1]),
        .mac_rst(qsfp_mac_tx_rst[0*2 +: 2*1]),

        .mac_ptp_time(qsfp_mac_tx_ptp_time[0*2*PTP_TS_WIDTH +: 2*PTP_TS_WIDTH]),

        .mac_tx_ptp_ts(qsfp_mac_tx_ptp_ts[0*2*PTP_TS_WIDTH +: 2*PTP_TS_WIDTH]),
        .mac_tx_ptp_ts_tag(qsfp_mac_tx_ptp_ts_tag[0*2*TX_TAG_WIDTH +: 2*TX_TAG_WIDTH]),
        .mac_tx_ptp_ts_valid(qsfp_mac_tx_ptp_ts_valid[0*2 +: 2*1]),

        .mac_tx_axis_tdata(qsfp_mac_tx_axis_tdata[0*2*AXIS_ETH_DATA_WIDTH +: 2*AXIS_ETH_DATA_WIDTH]),
        .mac_tx_axis_tkeep(qsfp_mac_tx_axis_tkeep[0*2*AXIS_ETH_KEEP_WIDTH +: 2*AXIS_ETH_KEEP_WIDTH]),
        .mac_tx_axis_tvalid(qsfp_mac_tx_axis_tvalid[0*2 +: 2*1]),
        .mac_tx_axis_tready(qsfp_mac_tx_axis_tready[0*2 +: 2*1]),
        .mac_tx_axis_tlast(qsfp_mac_tx_axis_tlast[0*2 +: 2*1]),
        .mac_tx_axis_tuser(qsfp_mac_tx_axis_tuser[0*2*AXIS_ETH_TX_USER_WIDTH +: 2*AXIS_ETH_TX_USER_WIDTH]),

        .mac_tx_status(qsfp_mac_tx_status[0*2 +: 2*1]),
        .mac_tx_lfc_req(qsfp_mac_tx_lfc_req[0*2 +: 2*1]),
        .mac_tx_pfc_req(qsfp_mac_tx_pfc_req[0*2*8 +: 2*8]),

        .mac_rx_axis_tdata(qsfp_mac_rx_axis_tdata[0*2*AXIS_ETH_DATA_WIDTH +: 2*AXIS_ETH_DATA_WIDTH]),
        .mac_rx_axis_tkeep(qsfp_mac_rx_axis_tkeep[0*2*AXIS_ETH_KEEP_WIDTH +: 2*AXIS_ETH_KEEP_WIDTH]),
        .mac_rx_axis_tvalid(qsfp_mac_rx_axis_tvalid[0*2 +: 2*1]),
        .mac_rx_axis_tlast(qsfp_mac_rx_axis_tlast[0*2 +: 2*1]),
        .mac_rx_axis_tuser(qsfp_mac_rx_axis_tuser[0*2*AXIS_ETH_RX_USER_WIDTH +: 2*AXIS_ETH_RX_USER_WIDTH]),

        .mac_rx_status(qsfp_mac_rx_status[0*2 +: 2*1]),
        .mac_rx_lfc_req(qsfp_mac_rx_lfc_req[0*2 +: 2*1]),
        .mac_rx_pfc_req(qsfp_mac_rx_pfc_req[0*2*8 +: 2*8])
    );

end else begin

    wire etile_iopll_locked;
    wire etile_ptp_sample_clk;

    iopll_etile_ptp iopll_etile_ptp_inst (
        .rst      (rst_50mhz),
        .refclk   (clk_50mhz),
        .locked   (etile_iopll_locked),
        .outclk_0 (etile_ptp_sample_clk)
    );

    // QSFP-DD
    eth_mac_dual_quad_wrapper #(
        .PTP_TS_WIDTH(PTP_TS_WIDTH),
        .PTP_TAG_WIDTH(PTP_TAG_WIDTH),
        .DATA_WIDTH(AXIS_ETH_DATA_WIDTH),
        .KEEP_WIDTH(AXIS_ETH_KEEP_WIDTH),
        .TX_USER_WIDTH(AXIS_ETH_TX_USER_WIDTH),
        .RX_USER_WIDTH(AXIS_ETH_RX_USER_WIDTH),
        .MAC_RSFEC(MAC_RSFEC)
    )
    qsfp_mac_inst (
        .ctrl_clk(clk_50mhz),
        .ctrl_rst(rst_50mhz),

        .tx_serial_data_p({qsfp_tx_p[7], qsfp_tx_p[5], qsfp_tx_p[6], qsfp_tx_p[4], qsfp_tx_p[3], qsfp_tx_p[1], qsfp_tx_p[2], qsfp_tx_p[0]}),
        // .tx_serial_data_n({qsfp_tx_n[7], qsfp_tx_n[5], qsfp_tx_n[6], qsfp_tx_n[4], qsfp_tx_n[3], qsfp_tx_n[1], qsfp_tx_n[2], qsfp_tx_n[0]}),
        .rx_serial_data_p({qsfp_rx_p[7], qsfp_rx_p[5], qsfp_rx_p[6], qsfp_rx_p[4], qsfp_rx_p[3], qsfp_rx_p[1], qsfp_rx_p[2], qsfp_rx_p[0]}),
        // .rx_serial_data_n({qsfp_rx_n[7], qsfp_rx_n[5], qsfp_rx_n[6], qsfp_rx_n[4], qsfp_rx_n[3], qsfp_rx_n[1], qsfp_rx_n[2], qsfp_rx_n[0]}),
        .ref_clk(qsfp_refclk_156m_p),
        .ptp_sample_clk(etile_ptp_sample_clk),

        .mac_tx_clk(qsfp_mac_tx_clk[0*8 +: 8*1]),
        .mac_tx_rst(qsfp_mac_tx_rst[0*8 +: 8*1]),

        .mac_tx_ptp_clk(qsfp_mac_tx_ptp_clk[0*8 +: 8*1]),
        .mac_tx_ptp_rst(qsfp_mac_tx_ptp_rst[0*8 +: 8*1]),
        .mac_tx_ptp_time(qsfp_mac_tx_ptp_time[0*8*PTP_TS_WIDTH +: 8*PTP_TS_WIDTH]),

        .mac_tx_ptp_ts(qsfp_mac_tx_ptp_ts[0*8*PTP_TS_WIDTH +: 8*PTP_TS_WIDTH]),
        .mac_tx_ptp_ts_tag(qsfp_mac_tx_ptp_ts_tag[0*8*TX_TAG_WIDTH +: 8*TX_TAG_WIDTH]),
        .mac_tx_ptp_ts_valid(qsfp_mac_tx_ptp_ts_valid[0*8 +: 8*1]),

        .mac_tx_axis_tdata(qsfp_mac_tx_axis_tdata[0*8*AXIS_ETH_DATA_WIDTH +: 8*AXIS_ETH_DATA_WIDTH]),
        .mac_tx_axis_tkeep(qsfp_mac_tx_axis_tkeep[0*8*AXIS_ETH_KEEP_WIDTH +: 8*AXIS_ETH_KEEP_WIDTH]),
        .mac_tx_axis_tvalid(qsfp_mac_tx_axis_tvalid[0*8 +: 8*1]),
        .mac_tx_axis_tready(qsfp_mac_tx_axis_tready[0*8 +: 8*1]),
        .mac_tx_axis_tlast(qsfp_mac_tx_axis_tlast[0*8 +: 8*1]),
        .mac_tx_axis_tuser(qsfp_mac_tx_axis_tuser[0*8*AXIS_ETH_TX_USER_WIDTH +: 8*AXIS_ETH_TX_USER_WIDTH]),

        .mac_tx_status(qsfp_mac_tx_status[0*8 +: 8*1]),
        .mac_tx_lfc_req(qsfp_mac_tx_lfc_req[0*8 +: 8*1]),
        .mac_tx_pfc_req(qsfp_mac_tx_pfc_req[0*8*8 +: 8*8]),

        .mac_rx_clk(qsfp_mac_rx_clk[0*8 +: 8*1]),
        .mac_rx_rst(qsfp_mac_rx_rst[0*8 +: 8*1]),

        .mac_rx_ptp_clk(qsfp_mac_rx_ptp_clk[0*8 +: 8*1]),
        .mac_rx_ptp_rst(qsfp_mac_rx_ptp_rst[0*8 +: 8*1]),
        .mac_rx_ptp_time(qsfp_mac_rx_ptp_time[0*8*PTP_TS_WIDTH +: 8*PTP_TS_WIDTH]),

        .mac_rx_axis_tdata(qsfp_mac_rx_axis_tdata[0*8*AXIS_ETH_DATA_WIDTH +: 8*AXIS_ETH_DATA_WIDTH]),
        .mac_rx_axis_tkeep(qsfp_mac_rx_axis_tkeep[0*8*AXIS_ETH_KEEP_WIDTH +: 8*AXIS_ETH_KEEP_WIDTH]),
        .mac_rx_axis_tvalid(qsfp_mac_rx_axis_tvalid[0*8 +: 8*1]),
        .mac_rx_axis_tlast(qsfp_mac_rx_axis_tlast[0*8 +: 8*1]),
        .mac_rx_axis_tuser(qsfp_mac_rx_axis_tuser[0*8*AXIS_ETH_RX_USER_WIDTH +: 8*AXIS_ETH_RX_USER_WIDTH]),

        .mac_rx_status(qsfp_mac_rx_status[0*8 +: 8*1]),
        .mac_rx_lfc_req(qsfp_mac_rx_lfc_req[0*8 +: 8*1]),
        .mac_rx_pfc_req(qsfp_mac_rx_pfc_req[0*8*8 +: 8*8])
    );

end

endgenerate

wire ptp_clk;
wire ptp_rst;
wire ptp_sample_clk;

assign ptp_sample_clk = clk_50mhz;

assign ptp_clk = qsfp_mac_tx_clk[0];
assign ptp_rst = qsfp_mac_tx_rst[0];

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
    .QSFP_CNT(QSFP_CNT),
    .CH_CNT(CH_CNT),
    .PORT_GROUP_SIZE(MAC_100G ? 2 : 8),

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
    .PTP_SEPARATE_TX_CLOCK(MAC_100G ? 0 : 1),
    .PTP_SEPARATE_RX_CLOCK(MAC_100G ? 0 : 1),
    .PTP_PORT_CDC_PIPELINE(PTP_PORT_CDC_PIPELINE),
    .PTP_PEROUT_ENABLE(PTP_PEROUT_ENABLE),
    .PTP_PEROUT_COUNT(PTP_PEROUT_COUNT),

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
    .TX_FIFO_DEPTH(TX_FIFO_DEPTH),
    .RX_FIFO_DEPTH(RX_FIFO_DEPTH),
    .MAX_TX_SIZE(MAX_TX_SIZE),
    .MAX_RX_SIZE(MAX_RX_SIZE),
    .TX_RAM_SIZE(TX_RAM_SIZE),
    .RX_RAM_SIZE(RX_RAM_SIZE),

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
    .SEG_COUNT(SEG_COUNT),
    .SEG_DATA_WIDTH(SEG_DATA_WIDTH),
    .SEG_EMPTY_WIDTH(SEG_EMPTY_WIDTH),
    .SEG_HDR_WIDTH(SEG_HDR_WIDTH),
    .SEG_PRFX_WIDTH(SEG_PRFX_WIDTH),
    .TX_SEQ_NUM_WIDTH(TX_SEQ_NUM_WIDTH),
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
    .clk_250mhz(pcie_clk),
    .rst_250mhz(pcie_rst),

    /*
     * PTP clock
     */
    .ptp_clk(ptp_clk),
    .ptp_rst(ptp_rst),
    .ptp_sample_clk(ptp_sample_clk),

    /*
     * GPIO
     */
    .user_led_g(user_led_g),
    .user_led_r(user_led_r),

    /*
     * I2C
     */
    .fpga_i2c_scl_i(fpga_i2c_scl_i),
    .fpga_i2c_scl_o(fpga_i2c_scl_o),
    .fpga_i2c_scl_t(fpga_i2c_scl_t),
    .fpga_i2c_sda_i(fpga_i2c_sda_i),
    .fpga_i2c_sda_o(fpga_i2c_sda_o),
    .fpga_i2c_sda_t(fpga_i2c_sda_t),

    /*
     * P-Tile interface
     */
    .rx_st_data(rx_st_data),
    .rx_st_empty(rx_st_empty),
    .rx_st_sop(rx_st_sop),
    .rx_st_eop(rx_st_eop),
    .rx_st_valid(rx_st_valid),
    .rx_st_ready(rx_st_ready),
    .rx_st_hdr(rx_st_hdr),
    .rx_st_tlp_prfx(rx_st_tlp_prfx),
    .rx_st_vf_active(rx_st_vf_active),
    .rx_st_func_num(rx_st_func_num),
    .rx_st_vf_num(rx_st_vf_num),
    .rx_st_bar_range(rx_st_bar_range),
    .rx_st_tlp_abort(rx_st_tlp_abort),

    .tx_st_data(tx_st_data),
    .tx_st_sop(tx_st_sop),
    .tx_st_eop(tx_st_eop),
    .tx_st_valid(tx_st_valid),
    .tx_st_ready(tx_st_ready),
    .tx_st_err(tx_st_err),
    .tx_st_hdr(tx_st_hdr),
    .tx_st_tlp_prfx(tx_st_tlp_prfx),

    .rx_buffer_limit(rx_buffer_limit),
    .rx_buffer_limit_tdm_idx(rx_buffer_limit_tdm_idx),

    .tx_cdts_limit(tx_cdts_limit),
    .tx_cdts_limit_tdm_idx(tx_cdts_limit_tdm_idx),

    .tl_cfg_ctl(tl_cfg_ctl),
    .tl_cfg_add(tl_cfg_add),
    .tl_cfg_func(tl_cfg_func),

    /*
     * Ethernet: QSFP-DD
     */
    .qsfp_mac_tx_clk(qsfp_mac_tx_clk),
    .qsfp_mac_tx_rst(qsfp_mac_tx_rst),

    .qsfp_mac_tx_axis_tdata(qsfp_mac_tx_axis_tdata),
    .qsfp_mac_tx_axis_tkeep(qsfp_mac_tx_axis_tkeep),
    .qsfp_mac_tx_axis_tvalid(qsfp_mac_tx_axis_tvalid),
    .qsfp_mac_tx_axis_tready(qsfp_mac_tx_axis_tready),
    .qsfp_mac_tx_axis_tlast(qsfp_mac_tx_axis_tlast),
    .qsfp_mac_tx_axis_tuser(qsfp_mac_tx_axis_tuser),

    .qsfp_mac_tx_ptp_clk(qsfp_mac_tx_ptp_clk),
    .qsfp_mac_tx_ptp_rst(qsfp_mac_tx_ptp_rst),
    .qsfp_mac_tx_ptp_time(qsfp_mac_tx_ptp_time),

    .qsfp_mac_tx_ptp_ts(qsfp_mac_tx_ptp_ts),
    .qsfp_mac_tx_ptp_ts_tag(qsfp_mac_tx_ptp_ts_tag),
    .qsfp_mac_tx_ptp_ts_valid(qsfp_mac_tx_ptp_ts_valid),

    .qsfp_mac_tx_status(qsfp_mac_tx_status),
    .qsfp_mac_tx_lfc_req(qsfp_mac_tx_lfc_req),
    .qsfp_mac_tx_pfc_req(qsfp_mac_tx_pfc_req),

    .qsfp_mac_rx_clk(qsfp_mac_rx_clk),
    .qsfp_mac_rx_rst(qsfp_mac_rx_rst),

    .qsfp_mac_rx_axis_tdata(qsfp_mac_rx_axis_tdata),
    .qsfp_mac_rx_axis_tkeep(qsfp_mac_rx_axis_tkeep),
    .qsfp_mac_rx_axis_tvalid(qsfp_mac_rx_axis_tvalid),
    .qsfp_mac_rx_axis_tlast(qsfp_mac_rx_axis_tlast),
    .qsfp_mac_rx_axis_tuser(qsfp_mac_rx_axis_tuser),

    .qsfp_mac_rx_ptp_clk(qsfp_mac_rx_ptp_clk),
    .qsfp_mac_rx_ptp_rst(qsfp_mac_rx_ptp_rst),
    .qsfp_mac_rx_ptp_time(qsfp_mac_rx_ptp_time),

    .qsfp_mac_rx_status(qsfp_mac_rx_status),
    .qsfp_mac_rx_lfc_req(qsfp_mac_rx_lfc_req),
    .qsfp_mac_rx_pfc_req(qsfp_mac_rx_pfc_req)
);

endmodule

`resetall
