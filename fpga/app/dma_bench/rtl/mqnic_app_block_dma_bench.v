// SPDX-License-Identifier: BSD-2-Clause-Views
/*
 * Copyright (c) 2021-2023 The Regents of the University of California
 */

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Application block (DMA benchmark application)
 */
module mqnic_app_block #
(
    // Structural configuration
    parameter IF_COUNT = 1,
    parameter PORTS_PER_IF = 1,
    parameter SCHED_PER_IF = PORTS_PER_IF,

    parameter PORT_COUNT = IF_COUNT*PORTS_PER_IF,

    // Clock configuration
    parameter CLK_PERIOD_NS_NUM = 4,
    parameter CLK_PERIOD_NS_DENOM = 1,

    // PTP configuration
    parameter PTP_CLK_PERIOD_NS_NUM = 4,
    parameter PTP_CLK_PERIOD_NS_DENOM = 1,
    parameter PTP_TS_WIDTH = 96,
    parameter PTP_PORT_CDC_PIPELINE = 0,
    parameter PTP_PEROUT_ENABLE = 0,
    parameter PTP_PEROUT_COUNT = 1,

    // Interface configuration
    parameter PTP_TS_ENABLE = 1,
    parameter TX_TAG_WIDTH = 16,
    parameter MAX_TX_SIZE = 9214,
    parameter MAX_RX_SIZE = 9214,

    // RAM configuration
    parameter DDR_CH = 1,
    parameter DDR_ENABLE = 0,
    parameter DDR_GROUP_SIZE = 1,
    parameter AXI_DDR_DATA_WIDTH = 256,
    parameter AXI_DDR_ADDR_WIDTH = 32,
    parameter AXI_DDR_STRB_WIDTH = (AXI_DDR_DATA_WIDTH/8),
    parameter AXI_DDR_ID_WIDTH = 8,
    parameter AXI_DDR_AWUSER_ENABLE = 0,
    parameter AXI_DDR_AWUSER_WIDTH = 1,
    parameter AXI_DDR_WUSER_ENABLE = 0,
    parameter AXI_DDR_WUSER_WIDTH = 1,
    parameter AXI_DDR_BUSER_ENABLE = 0,
    parameter AXI_DDR_BUSER_WIDTH = 1,
    parameter AXI_DDR_ARUSER_ENABLE = 0,
    parameter AXI_DDR_ARUSER_WIDTH = 1,
    parameter AXI_DDR_RUSER_ENABLE = 0,
    parameter AXI_DDR_RUSER_WIDTH = 1,
    parameter AXI_DDR_MAX_BURST_LEN = 256,
    parameter AXI_DDR_NARROW_BURST = 0,
    parameter AXI_DDR_FIXED_BURST = 0,
    parameter AXI_DDR_WRAP_BURST = 0,
    parameter HBM_CH = 1,
    parameter HBM_ENABLE = 0,
    parameter HBM_GROUP_SIZE = 1,
    parameter AXI_HBM_DATA_WIDTH = 256,
    parameter AXI_HBM_ADDR_WIDTH = 32,
    parameter AXI_HBM_STRB_WIDTH = (AXI_HBM_DATA_WIDTH/8),
    parameter AXI_HBM_ID_WIDTH = 8,
    parameter AXI_HBM_AWUSER_ENABLE = 0,
    parameter AXI_HBM_AWUSER_WIDTH = 1,
    parameter AXI_HBM_WUSER_ENABLE = 0,
    parameter AXI_HBM_WUSER_WIDTH = 1,
    parameter AXI_HBM_BUSER_ENABLE = 0,
    parameter AXI_HBM_BUSER_WIDTH = 1,
    parameter AXI_HBM_ARUSER_ENABLE = 0,
    parameter AXI_HBM_ARUSER_WIDTH = 1,
    parameter AXI_HBM_RUSER_ENABLE = 0,
    parameter AXI_HBM_RUSER_WIDTH = 1,
    parameter AXI_HBM_MAX_BURST_LEN = 256,
    parameter AXI_HBM_NARROW_BURST = 0,
    parameter AXI_HBM_FIXED_BURST = 0,
    parameter AXI_HBM_WRAP_BURST = 0,

    // Application configuration
    parameter APP_ID = 32'h12348001,
    parameter APP_CTRL_ENABLE = 1,
    parameter APP_DMA_ENABLE = 1,
    parameter APP_AXIS_DIRECT_ENABLE = 1,
    parameter APP_AXIS_SYNC_ENABLE = 1,
    parameter APP_AXIS_IF_ENABLE = 1,
    parameter APP_STAT_ENABLE = 1,
    parameter APP_GPIO_IN_WIDTH = 32,
    parameter APP_GPIO_OUT_WIDTH = 32,

    // DMA interface configuration
    parameter DMA_ADDR_WIDTH = 64,
    parameter DMA_IMM_ENABLE = 0,
    parameter DMA_IMM_WIDTH = 32,
    parameter DMA_LEN_WIDTH = 16,
    parameter DMA_TAG_WIDTH = 16,
    parameter RAM_SEL_WIDTH = 4,
    parameter RAM_ADDR_WIDTH = 16,
    parameter RAM_SEG_COUNT = 2,
    parameter RAM_SEG_DATA_WIDTH = 256*2/RAM_SEG_COUNT,
    parameter RAM_SEG_BE_WIDTH = RAM_SEG_DATA_WIDTH/8,
    parameter RAM_SEG_ADDR_WIDTH = RAM_ADDR_WIDTH-$clog2(RAM_SEG_COUNT*RAM_SEG_BE_WIDTH),
    parameter RAM_PIPELINE = 2,

    // AXI lite interface (application control from host)
    parameter AXIL_APP_CTRL_DATA_WIDTH = 32,
    parameter AXIL_APP_CTRL_ADDR_WIDTH = 16,
    parameter AXIL_APP_CTRL_STRB_WIDTH = (AXIL_APP_CTRL_DATA_WIDTH/8),

    // AXI lite interface (control to NIC)
    parameter AXIL_CTRL_DATA_WIDTH = 32,
    parameter AXIL_CTRL_ADDR_WIDTH = 16,
    parameter AXIL_CTRL_STRB_WIDTH = (AXIL_CTRL_DATA_WIDTH/8),

    // Ethernet interface configuration (direct, async)
    parameter AXIS_DATA_WIDTH = 512,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter AXIS_TX_USER_WIDTH = TX_TAG_WIDTH + 1,
    parameter AXIS_RX_USER_WIDTH = (PTP_TS_ENABLE ? PTP_TS_WIDTH : 0) + 1,
    parameter AXIS_RX_USE_READY = 0,

    // Ethernet interface configuration (direct, sync)
    parameter AXIS_SYNC_DATA_WIDTH = AXIS_DATA_WIDTH,
    parameter AXIS_SYNC_KEEP_WIDTH = AXIS_SYNC_DATA_WIDTH/8,
    parameter AXIS_SYNC_TX_USER_WIDTH = AXIS_TX_USER_WIDTH,
    parameter AXIS_SYNC_RX_USER_WIDTH = AXIS_RX_USER_WIDTH,

    // Ethernet interface configuration (interface)
    parameter AXIS_IF_DATA_WIDTH = AXIS_SYNC_DATA_WIDTH*2**$clog2(PORTS_PER_IF),
    parameter AXIS_IF_KEEP_WIDTH = AXIS_IF_DATA_WIDTH/8,
    parameter AXIS_IF_TX_ID_WIDTH = 12,
    parameter AXIS_IF_RX_ID_WIDTH = PORTS_PER_IF > 1 ? $clog2(PORTS_PER_IF) : 1,
    parameter AXIS_IF_TX_DEST_WIDTH = $clog2(PORTS_PER_IF)+4,
    parameter AXIS_IF_RX_DEST_WIDTH = 8,
    parameter AXIS_IF_TX_USER_WIDTH = AXIS_SYNC_TX_USER_WIDTH,
    parameter AXIS_IF_RX_USER_WIDTH = AXIS_SYNC_RX_USER_WIDTH,

    // Statistics counter subsystem
    parameter STAT_ENABLE = 1,
    parameter STAT_INC_WIDTH = 24,
    parameter STAT_ID_WIDTH = 12
)
(
    input  wire                                           clk,
    input  wire                                           rst,

    /*
     * AXI-Lite slave interface (control from host)
     */
    input  wire [AXIL_APP_CTRL_ADDR_WIDTH-1:0]            s_axil_app_ctrl_awaddr,
    input  wire [2:0]                                     s_axil_app_ctrl_awprot,
    input  wire                                           s_axil_app_ctrl_awvalid,
    output wire                                           s_axil_app_ctrl_awready,
    input  wire [AXIL_APP_CTRL_DATA_WIDTH-1:0]            s_axil_app_ctrl_wdata,
    input  wire [AXIL_APP_CTRL_STRB_WIDTH-1:0]            s_axil_app_ctrl_wstrb,
    input  wire                                           s_axil_app_ctrl_wvalid,
    output wire                                           s_axil_app_ctrl_wready,
    output wire [1:0]                                     s_axil_app_ctrl_bresp,
    output wire                                           s_axil_app_ctrl_bvalid,
    input  wire                                           s_axil_app_ctrl_bready,
    input  wire [AXIL_APP_CTRL_ADDR_WIDTH-1:0]            s_axil_app_ctrl_araddr,
    input  wire [2:0]                                     s_axil_app_ctrl_arprot,
    input  wire                                           s_axil_app_ctrl_arvalid,
    output wire                                           s_axil_app_ctrl_arready,
    output wire [AXIL_APP_CTRL_DATA_WIDTH-1:0]            s_axil_app_ctrl_rdata,
    output wire [1:0]                                     s_axil_app_ctrl_rresp,
    output wire                                           s_axil_app_ctrl_rvalid,
    input  wire                                           s_axil_app_ctrl_rready,

    /*
     * AXI-Lite master interface (control to NIC)
     */
    output wire [AXIL_CTRL_ADDR_WIDTH-1:0]                m_axil_ctrl_awaddr,
    output wire [2:0]                                     m_axil_ctrl_awprot,
    output wire                                           m_axil_ctrl_awvalid,
    input  wire                                           m_axil_ctrl_awready,
    output wire [AXIL_CTRL_DATA_WIDTH-1:0]                m_axil_ctrl_wdata,
    output wire [AXIL_CTRL_STRB_WIDTH-1:0]                m_axil_ctrl_wstrb,
    output wire                                           m_axil_ctrl_wvalid,
    input  wire                                           m_axil_ctrl_wready,
    input  wire [1:0]                                     m_axil_ctrl_bresp,
    input  wire                                           m_axil_ctrl_bvalid,
    output wire                                           m_axil_ctrl_bready,
    output wire [AXIL_CTRL_ADDR_WIDTH-1:0]                m_axil_ctrl_araddr,
    output wire [2:0]                                     m_axil_ctrl_arprot,
    output wire                                           m_axil_ctrl_arvalid,
    input  wire                                           m_axil_ctrl_arready,
    input  wire [AXIL_CTRL_DATA_WIDTH-1:0]                m_axil_ctrl_rdata,
    input  wire [1:0]                                     m_axil_ctrl_rresp,
    input  wire                                           m_axil_ctrl_rvalid,
    output wire                                           m_axil_ctrl_rready,

    /*
     * DMA read descriptor output (control)
     */
    output wire [DMA_ADDR_WIDTH-1:0]                      m_axis_ctrl_dma_read_desc_dma_addr,
    output wire [RAM_SEL_WIDTH-1:0]                       m_axis_ctrl_dma_read_desc_ram_sel,
    output wire [RAM_ADDR_WIDTH-1:0]                      m_axis_ctrl_dma_read_desc_ram_addr,
    output wire [DMA_LEN_WIDTH-1:0]                       m_axis_ctrl_dma_read_desc_len,
    output wire [DMA_TAG_WIDTH-1:0]                       m_axis_ctrl_dma_read_desc_tag,
    output wire                                           m_axis_ctrl_dma_read_desc_valid,
    input  wire                                           m_axis_ctrl_dma_read_desc_ready,

    /*
     * DMA read descriptor status input (control)
     */
    input  wire [DMA_TAG_WIDTH-1:0]                       s_axis_ctrl_dma_read_desc_status_tag,
    input  wire [3:0]                                     s_axis_ctrl_dma_read_desc_status_error,
    input  wire                                           s_axis_ctrl_dma_read_desc_status_valid,

    /*
     * DMA write descriptor output (control)
     */
    output wire [DMA_ADDR_WIDTH-1:0]                      m_axis_ctrl_dma_write_desc_dma_addr,
    output wire [RAM_SEL_WIDTH-1:0]                       m_axis_ctrl_dma_write_desc_ram_sel,
    output wire [RAM_ADDR_WIDTH-1:0]                      m_axis_ctrl_dma_write_desc_ram_addr,
    output wire [DMA_IMM_WIDTH-1:0]                       m_axis_ctrl_dma_write_desc_imm,
    output wire                                           m_axis_ctrl_dma_write_desc_imm_en,
    output wire [DMA_LEN_WIDTH-1:0]                       m_axis_ctrl_dma_write_desc_len,
    output wire [DMA_TAG_WIDTH-1:0]                       m_axis_ctrl_dma_write_desc_tag,
    output wire                                           m_axis_ctrl_dma_write_desc_valid,
    input  wire                                           m_axis_ctrl_dma_write_desc_ready,

    /*
     * DMA write descriptor status input (control)
     */
    input  wire [DMA_TAG_WIDTH-1:0]                       s_axis_ctrl_dma_write_desc_status_tag,
    input  wire [3:0]                                     s_axis_ctrl_dma_write_desc_status_error,
    input  wire                                           s_axis_ctrl_dma_write_desc_status_valid,

    /*
     * DMA read descriptor output (data)
     */
    output wire [DMA_ADDR_WIDTH-1:0]                      m_axis_data_dma_read_desc_dma_addr,
    output wire [RAM_SEL_WIDTH-1:0]                       m_axis_data_dma_read_desc_ram_sel,
    output wire [RAM_ADDR_WIDTH-1:0]                      m_axis_data_dma_read_desc_ram_addr,
    output wire [DMA_LEN_WIDTH-1:0]                       m_axis_data_dma_read_desc_len,
    output wire [DMA_TAG_WIDTH-1:0]                       m_axis_data_dma_read_desc_tag,
    output wire                                           m_axis_data_dma_read_desc_valid,
    input  wire                                           m_axis_data_dma_read_desc_ready,

    /*
     * DMA read descriptor status input (data)
     */
    input  wire [DMA_TAG_WIDTH-1:0]                       s_axis_data_dma_read_desc_status_tag,
    input  wire [3:0]                                     s_axis_data_dma_read_desc_status_error,
    input  wire                                           s_axis_data_dma_read_desc_status_valid,

    /*
     * DMA write descriptor output (data)
     */
    output wire [DMA_ADDR_WIDTH-1:0]                      m_axis_data_dma_write_desc_dma_addr,
    output wire [RAM_SEL_WIDTH-1:0]                       m_axis_data_dma_write_desc_ram_sel,
    output wire [RAM_ADDR_WIDTH-1:0]                      m_axis_data_dma_write_desc_ram_addr,
    output wire [DMA_IMM_WIDTH-1:0]                       m_axis_data_dma_write_desc_imm,
    output wire                                           m_axis_data_dma_write_desc_imm_en,
    output wire [DMA_LEN_WIDTH-1:0]                       m_axis_data_dma_write_desc_len,
    output wire [DMA_TAG_WIDTH-1:0]                       m_axis_data_dma_write_desc_tag,
    output wire                                           m_axis_data_dma_write_desc_valid,
    input  wire                                           m_axis_data_dma_write_desc_ready,

    /*
     * DMA write descriptor status input (data)
     */
    input  wire [DMA_TAG_WIDTH-1:0]                       s_axis_data_dma_write_desc_status_tag,
    input  wire [3:0]                                     s_axis_data_dma_write_desc_status_error,
    input  wire                                           s_axis_data_dma_write_desc_status_valid,

    /*
     * DMA RAM interface (control)
     */
    input  wire [RAM_SEG_COUNT*RAM_SEL_WIDTH-1:0]         ctrl_dma_ram_wr_cmd_sel,
    input  wire [RAM_SEG_COUNT*RAM_SEG_BE_WIDTH-1:0]      ctrl_dma_ram_wr_cmd_be,
    input  wire [RAM_SEG_COUNT*RAM_SEG_ADDR_WIDTH-1:0]    ctrl_dma_ram_wr_cmd_addr,
    input  wire [RAM_SEG_COUNT*RAM_SEG_DATA_WIDTH-1:0]    ctrl_dma_ram_wr_cmd_data,
    input  wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_wr_cmd_valid,
    output wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_wr_cmd_ready,
    output wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_wr_done,
    input  wire [RAM_SEG_COUNT*RAM_SEL_WIDTH-1:0]         ctrl_dma_ram_rd_cmd_sel,
    input  wire [RAM_SEG_COUNT*RAM_SEG_ADDR_WIDTH-1:0]    ctrl_dma_ram_rd_cmd_addr,
    input  wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_rd_cmd_valid,
    output wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_rd_cmd_ready,
    output wire [RAM_SEG_COUNT*RAM_SEG_DATA_WIDTH-1:0]    ctrl_dma_ram_rd_resp_data,
    output wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_rd_resp_valid,
    input  wire [RAM_SEG_COUNT-1:0]                       ctrl_dma_ram_rd_resp_ready,

    /*
     * DMA RAM interface (data)
     */
    input  wire [RAM_SEG_COUNT*RAM_SEL_WIDTH-1:0]         data_dma_ram_wr_cmd_sel,
    input  wire [RAM_SEG_COUNT*RAM_SEG_BE_WIDTH-1:0]      data_dma_ram_wr_cmd_be,
    input  wire [RAM_SEG_COUNT*RAM_SEG_ADDR_WIDTH-1:0]    data_dma_ram_wr_cmd_addr,
    input  wire [RAM_SEG_COUNT*RAM_SEG_DATA_WIDTH-1:0]    data_dma_ram_wr_cmd_data,
    input  wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_wr_cmd_valid,
    output wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_wr_cmd_ready,
    output wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_wr_done,
    input  wire [RAM_SEG_COUNT*RAM_SEL_WIDTH-1:0]         data_dma_ram_rd_cmd_sel,
    input  wire [RAM_SEG_COUNT*RAM_SEG_ADDR_WIDTH-1:0]    data_dma_ram_rd_cmd_addr,
    input  wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_rd_cmd_valid,
    output wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_rd_cmd_ready,
    output wire [RAM_SEG_COUNT*RAM_SEG_DATA_WIDTH-1:0]    data_dma_ram_rd_resp_data,
    output wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_rd_resp_valid,
    input  wire [RAM_SEG_COUNT-1:0]                       data_dma_ram_rd_resp_ready,

    /*
     * PTP clock
     */
    input  wire                                           ptp_clk,
    input  wire                                           ptp_rst,
    input  wire                                           ptp_sample_clk,
    input  wire                                           ptp_td_sd,
    input  wire                                           ptp_pps,
    input  wire                                           ptp_pps_str,
    input  wire                                           ptp_sync_locked,
    input  wire [PTP_TS_WIDTH-1:0]                        ptp_sync_ts_rel,
    input  wire                                           ptp_sync_ts_rel_step,
    input  wire [PTP_TS_WIDTH-1:0]                        ptp_sync_ts_tod,
    input  wire                                           ptp_sync_ts_tod_step,
    input  wire                                           ptp_sync_pps,
    input  wire                                           ptp_sync_pps_str,
    input  wire [PTP_PEROUT_COUNT-1:0]                    ptp_perout_locked,
    input  wire [PTP_PEROUT_COUNT-1:0]                    ptp_perout_error,
    input  wire [PTP_PEROUT_COUNT-1:0]                    ptp_perout_pulse,

    /*
     * Ethernet (direct MAC interface - lowest latency raw traffic)
     */
    input  wire [PORT_COUNT-1:0]                          direct_tx_clk,
    input  wire [PORT_COUNT-1:0]                          direct_tx_rst,

    input  wire [PORT_COUNT*AXIS_DATA_WIDTH-1:0]          s_axis_direct_tx_tdata,
    input  wire [PORT_COUNT*AXIS_KEEP_WIDTH-1:0]          s_axis_direct_tx_tkeep,
    input  wire [PORT_COUNT-1:0]                          s_axis_direct_tx_tvalid,
    output wire [PORT_COUNT-1:0]                          s_axis_direct_tx_tready,
    input  wire [PORT_COUNT-1:0]                          s_axis_direct_tx_tlast,
    input  wire [PORT_COUNT*AXIS_TX_USER_WIDTH-1:0]       s_axis_direct_tx_tuser,

    output wire [PORT_COUNT*AXIS_DATA_WIDTH-1:0]          m_axis_direct_tx_tdata,
    output wire [PORT_COUNT*AXIS_KEEP_WIDTH-1:0]          m_axis_direct_tx_tkeep,
    output wire [PORT_COUNT-1:0]                          m_axis_direct_tx_tvalid,
    input  wire [PORT_COUNT-1:0]                          m_axis_direct_tx_tready,
    output wire [PORT_COUNT-1:0]                          m_axis_direct_tx_tlast,
    output wire [PORT_COUNT*AXIS_TX_USER_WIDTH-1:0]       m_axis_direct_tx_tuser,

    input  wire [PORT_COUNT*PTP_TS_WIDTH-1:0]             s_axis_direct_tx_cpl_ts,
    input  wire [PORT_COUNT*TX_TAG_WIDTH-1:0]             s_axis_direct_tx_cpl_tag,
    input  wire [PORT_COUNT-1:0]                          s_axis_direct_tx_cpl_valid,
    output wire [PORT_COUNT-1:0]                          s_axis_direct_tx_cpl_ready,

    output wire [PORT_COUNT*PTP_TS_WIDTH-1:0]             m_axis_direct_tx_cpl_ts,
    output wire [PORT_COUNT*TX_TAG_WIDTH-1:0]             m_axis_direct_tx_cpl_tag,
    output wire [PORT_COUNT-1:0]                          m_axis_direct_tx_cpl_valid,
    input  wire [PORT_COUNT-1:0]                          m_axis_direct_tx_cpl_ready,

    input  wire [PORT_COUNT-1:0]                          direct_rx_clk,
    input  wire [PORT_COUNT-1:0]                          direct_rx_rst,

    input  wire [PORT_COUNT*AXIS_DATA_WIDTH-1:0]          s_axis_direct_rx_tdata,
    input  wire [PORT_COUNT*AXIS_KEEP_WIDTH-1:0]          s_axis_direct_rx_tkeep,
    input  wire [PORT_COUNT-1:0]                          s_axis_direct_rx_tvalid,
    output wire [PORT_COUNT-1:0]                          s_axis_direct_rx_tready,
    input  wire [PORT_COUNT-1:0]                          s_axis_direct_rx_tlast,
    input  wire [PORT_COUNT*AXIS_RX_USER_WIDTH-1:0]       s_axis_direct_rx_tuser,

    output wire [PORT_COUNT*AXIS_DATA_WIDTH-1:0]          m_axis_direct_rx_tdata,
    output wire [PORT_COUNT*AXIS_KEEP_WIDTH-1:0]          m_axis_direct_rx_tkeep,
    output wire [PORT_COUNT-1:0]                          m_axis_direct_rx_tvalid,
    input  wire [PORT_COUNT-1:0]                          m_axis_direct_rx_tready,
    output wire [PORT_COUNT-1:0]                          m_axis_direct_rx_tlast,
    output wire [PORT_COUNT*AXIS_RX_USER_WIDTH-1:0]       m_axis_direct_rx_tuser,

    /*
     * Ethernet (synchronous MAC interface - low latency raw traffic)
     */
    input  wire [PORT_COUNT*AXIS_SYNC_DATA_WIDTH-1:0]     s_axis_sync_tx_tdata,
    input  wire [PORT_COUNT*AXIS_SYNC_KEEP_WIDTH-1:0]     s_axis_sync_tx_tkeep,
    input  wire [PORT_COUNT-1:0]                          s_axis_sync_tx_tvalid,
    output wire [PORT_COUNT-1:0]                          s_axis_sync_tx_tready,
    input  wire [PORT_COUNT-1:0]                          s_axis_sync_tx_tlast,
    input  wire [PORT_COUNT*AXIS_SYNC_TX_USER_WIDTH-1:0]  s_axis_sync_tx_tuser,

    output wire [PORT_COUNT*AXIS_SYNC_DATA_WIDTH-1:0]     m_axis_sync_tx_tdata,
    output wire [PORT_COUNT*AXIS_SYNC_KEEP_WIDTH-1:0]     m_axis_sync_tx_tkeep,
    output wire [PORT_COUNT-1:0]                          m_axis_sync_tx_tvalid,
    input  wire [PORT_COUNT-1:0]                          m_axis_sync_tx_tready,
    output wire [PORT_COUNT-1:0]                          m_axis_sync_tx_tlast,
    output wire [PORT_COUNT*AXIS_SYNC_TX_USER_WIDTH-1:0]  m_axis_sync_tx_tuser,

    input  wire [PORT_COUNT*PTP_TS_WIDTH-1:0]             s_axis_sync_tx_cpl_ts,
    input  wire [PORT_COUNT*TX_TAG_WIDTH-1:0]             s_axis_sync_tx_cpl_tag,
    input  wire [PORT_COUNT-1:0]                          s_axis_sync_tx_cpl_valid,
    output wire [PORT_COUNT-1:0]                          s_axis_sync_tx_cpl_ready,

    output wire [PORT_COUNT*PTP_TS_WIDTH-1:0]             m_axis_sync_tx_cpl_ts,
    output wire [PORT_COUNT*TX_TAG_WIDTH-1:0]             m_axis_sync_tx_cpl_tag,
    output wire [PORT_COUNT-1:0]                          m_axis_sync_tx_cpl_valid,
    input  wire [PORT_COUNT-1:0]                          m_axis_sync_tx_cpl_ready,

    input  wire [PORT_COUNT*AXIS_SYNC_DATA_WIDTH-1:0]     s_axis_sync_rx_tdata,
    input  wire [PORT_COUNT*AXIS_SYNC_KEEP_WIDTH-1:0]     s_axis_sync_rx_tkeep,
    input  wire [PORT_COUNT-1:0]                          s_axis_sync_rx_tvalid,
    output wire [PORT_COUNT-1:0]                          s_axis_sync_rx_tready,
    input  wire [PORT_COUNT-1:0]                          s_axis_sync_rx_tlast,
    input  wire [PORT_COUNT*AXIS_SYNC_RX_USER_WIDTH-1:0]  s_axis_sync_rx_tuser,

    output wire [PORT_COUNT*AXIS_SYNC_DATA_WIDTH-1:0]     m_axis_sync_rx_tdata,
    output wire [PORT_COUNT*AXIS_SYNC_KEEP_WIDTH-1:0]     m_axis_sync_rx_tkeep,
    output wire [PORT_COUNT-1:0]                          m_axis_sync_rx_tvalid,
    input  wire [PORT_COUNT-1:0]                          m_axis_sync_rx_tready,
    output wire [PORT_COUNT-1:0]                          m_axis_sync_rx_tlast,
    output wire [PORT_COUNT*AXIS_SYNC_RX_USER_WIDTH-1:0]  m_axis_sync_rx_tuser,

    /*
     * Ethernet (internal at interface module)
     */
    input  wire [IF_COUNT*AXIS_IF_DATA_WIDTH-1:0]         s_axis_if_tx_tdata,
    input  wire [IF_COUNT*AXIS_IF_KEEP_WIDTH-1:0]         s_axis_if_tx_tkeep,
    input  wire [IF_COUNT-1:0]                            s_axis_if_tx_tvalid,
    output wire [IF_COUNT-1:0]                            s_axis_if_tx_tready,
    input  wire [IF_COUNT-1:0]                            s_axis_if_tx_tlast,
    input  wire [IF_COUNT*AXIS_IF_TX_ID_WIDTH-1:0]        s_axis_if_tx_tid,
    input  wire [IF_COUNT*AXIS_IF_TX_DEST_WIDTH-1:0]      s_axis_if_tx_tdest,
    input  wire [IF_COUNT*AXIS_IF_TX_USER_WIDTH-1:0]      s_axis_if_tx_tuser,

    output wire [IF_COUNT*AXIS_IF_DATA_WIDTH-1:0]         m_axis_if_tx_tdata,
    output wire [IF_COUNT*AXIS_IF_KEEP_WIDTH-1:0]         m_axis_if_tx_tkeep,
    output wire [IF_COUNT-1:0]                            m_axis_if_tx_tvalid,
    input  wire [IF_COUNT-1:0]                            m_axis_if_tx_tready,
    output wire [IF_COUNT-1:0]                            m_axis_if_tx_tlast,
    output wire [IF_COUNT*AXIS_IF_TX_ID_WIDTH-1:0]        m_axis_if_tx_tid,
    output wire [IF_COUNT*AXIS_IF_TX_DEST_WIDTH-1:0]      m_axis_if_tx_tdest,
    output wire [IF_COUNT*AXIS_IF_TX_USER_WIDTH-1:0]      m_axis_if_tx_tuser,

    input  wire [IF_COUNT*PTP_TS_WIDTH-1:0]               s_axis_if_tx_cpl_ts,
    input  wire [IF_COUNT*TX_TAG_WIDTH-1:0]               s_axis_if_tx_cpl_tag,
    input  wire [IF_COUNT-1:0]                            s_axis_if_tx_cpl_valid,
    output wire [IF_COUNT-1:0]                            s_axis_if_tx_cpl_ready,

    output wire [IF_COUNT*PTP_TS_WIDTH-1:0]               m_axis_if_tx_cpl_ts,
    output wire [IF_COUNT*TX_TAG_WIDTH-1:0]               m_axis_if_tx_cpl_tag,
    output wire [IF_COUNT-1:0]                            m_axis_if_tx_cpl_valid,
    input  wire [IF_COUNT-1:0]                            m_axis_if_tx_cpl_ready,

    input  wire [IF_COUNT*AXIS_IF_DATA_WIDTH-1:0]         s_axis_if_rx_tdata,
    input  wire [IF_COUNT*AXIS_IF_KEEP_WIDTH-1:0]         s_axis_if_rx_tkeep,
    input  wire [IF_COUNT-1:0]                            s_axis_if_rx_tvalid,
    output wire [IF_COUNT-1:0]                            s_axis_if_rx_tready,
    input  wire [IF_COUNT-1:0]                            s_axis_if_rx_tlast,
    input  wire [IF_COUNT*AXIS_IF_RX_ID_WIDTH-1:0]        s_axis_if_rx_tid,
    input  wire [IF_COUNT*AXIS_IF_RX_DEST_WIDTH-1:0]      s_axis_if_rx_tdest,
    input  wire [IF_COUNT*AXIS_IF_RX_USER_WIDTH-1:0]      s_axis_if_rx_tuser,

    output wire [IF_COUNT*AXIS_IF_DATA_WIDTH-1:0]         m_axis_if_rx_tdata,
    output wire [IF_COUNT*AXIS_IF_KEEP_WIDTH-1:0]         m_axis_if_rx_tkeep,
    output wire [IF_COUNT-1:0]                            m_axis_if_rx_tvalid,
    input  wire [IF_COUNT-1:0]                            m_axis_if_rx_tready,
    output wire [IF_COUNT-1:0]                            m_axis_if_rx_tlast,
    output wire [IF_COUNT*AXIS_IF_RX_ID_WIDTH-1:0]        m_axis_if_rx_tid,
    output wire [IF_COUNT*AXIS_IF_RX_DEST_WIDTH-1:0]      m_axis_if_rx_tdest,
    output wire [IF_COUNT*AXIS_IF_RX_USER_WIDTH-1:0]      m_axis_if_rx_tuser,

    /*
     * DDR
     */
    input  wire [DDR_CH-1:0]                              ddr_clk,
    input  wire [DDR_CH-1:0]                              ddr_rst,

    output wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]             m_axi_ddr_awid,
    output wire [DDR_CH*AXI_DDR_ADDR_WIDTH-1:0]           m_axi_ddr_awaddr,
    output wire [DDR_CH*8-1:0]                            m_axi_ddr_awlen,
    output wire [DDR_CH*3-1:0]                            m_axi_ddr_awsize,
    output wire [DDR_CH*2-1:0]                            m_axi_ddr_awburst,
    output wire [DDR_CH-1:0]                              m_axi_ddr_awlock,
    output wire [DDR_CH*4-1:0]                            m_axi_ddr_awcache,
    output wire [DDR_CH*3-1:0]                            m_axi_ddr_awprot,
    output wire [DDR_CH*4-1:0]                            m_axi_ddr_awqos,
    output wire [DDR_CH*AXI_DDR_AWUSER_WIDTH-1:0]         m_axi_ddr_awuser,
    output wire [DDR_CH-1:0]                              m_axi_ddr_awvalid,
    input  wire [DDR_CH-1:0]                              m_axi_ddr_awready,
    output wire [DDR_CH*AXI_DDR_DATA_WIDTH-1:0]           m_axi_ddr_wdata,
    output wire [DDR_CH*AXI_DDR_STRB_WIDTH-1:0]           m_axi_ddr_wstrb,
    output wire [DDR_CH-1:0]                              m_axi_ddr_wlast,
    output wire [DDR_CH*AXI_DDR_WUSER_WIDTH-1:0]          m_axi_ddr_wuser,
    output wire [DDR_CH-1:0]                              m_axi_ddr_wvalid,
    input  wire [DDR_CH-1:0]                              m_axi_ddr_wready,
    input  wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]             m_axi_ddr_bid,
    input  wire [DDR_CH*2-1:0]                            m_axi_ddr_bresp,
    input  wire [DDR_CH*AXI_DDR_BUSER_WIDTH-1:0]          m_axi_ddr_buser,
    input  wire [DDR_CH-1:0]                              m_axi_ddr_bvalid,
    output wire [DDR_CH-1:0]                              m_axi_ddr_bready,
    output wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]             m_axi_ddr_arid,
    output wire [DDR_CH*AXI_DDR_ADDR_WIDTH-1:0]           m_axi_ddr_araddr,
    output wire [DDR_CH*8-1:0]                            m_axi_ddr_arlen,
    output wire [DDR_CH*3-1:0]                            m_axi_ddr_arsize,
    output wire [DDR_CH*2-1:0]                            m_axi_ddr_arburst,
    output wire [DDR_CH-1:0]                              m_axi_ddr_arlock,
    output wire [DDR_CH*4-1:0]                            m_axi_ddr_arcache,
    output wire [DDR_CH*3-1:0]                            m_axi_ddr_arprot,
    output wire [DDR_CH*4-1:0]                            m_axi_ddr_arqos,
    output wire [DDR_CH*AXI_DDR_ARUSER_WIDTH-1:0]         m_axi_ddr_aruser,
    output wire [DDR_CH-1:0]                              m_axi_ddr_arvalid,
    input  wire [DDR_CH-1:0]                              m_axi_ddr_arready,
    input  wire [DDR_CH*AXI_DDR_ID_WIDTH-1:0]             m_axi_ddr_rid,
    input  wire [DDR_CH*AXI_DDR_DATA_WIDTH-1:0]           m_axi_ddr_rdata,
    input  wire [DDR_CH*2-1:0]                            m_axi_ddr_rresp,
    input  wire [DDR_CH-1:0]                              m_axi_ddr_rlast,
    input  wire [DDR_CH*AXI_DDR_RUSER_WIDTH-1:0]          m_axi_ddr_ruser,
    input  wire [DDR_CH-1:0]                              m_axi_ddr_rvalid,
    output wire [DDR_CH-1:0]                              m_axi_ddr_rready,

    input  wire [DDR_CH-1:0]                              ddr_status,

    /*
     * HBM
     */
    input  wire [HBM_CH-1:0]                              hbm_clk,
    input  wire [HBM_CH-1:0]                              hbm_rst,

    output wire [HBM_CH*AXI_HBM_ID_WIDTH-1:0]             m_axi_hbm_awid,
    output wire [HBM_CH*AXI_HBM_ADDR_WIDTH-1:0]           m_axi_hbm_awaddr,
    output wire [HBM_CH*8-1:0]                            m_axi_hbm_awlen,
    output wire [HBM_CH*3-1:0]                            m_axi_hbm_awsize,
    output wire [HBM_CH*2-1:0]                            m_axi_hbm_awburst,
    output wire [HBM_CH-1:0]                              m_axi_hbm_awlock,
    output wire [HBM_CH*4-1:0]                            m_axi_hbm_awcache,
    output wire [HBM_CH*3-1:0]                            m_axi_hbm_awprot,
    output wire [HBM_CH*4-1:0]                            m_axi_hbm_awqos,
    output wire [HBM_CH*AXI_HBM_AWUSER_WIDTH-1:0]         m_axi_hbm_awuser,
    output wire [HBM_CH-1:0]                              m_axi_hbm_awvalid,
    input  wire [HBM_CH-1:0]                              m_axi_hbm_awready,
    output wire [HBM_CH*AXI_HBM_DATA_WIDTH-1:0]           m_axi_hbm_wdata,
    output wire [HBM_CH*AXI_HBM_STRB_WIDTH-1:0]           m_axi_hbm_wstrb,
    output wire [HBM_CH-1:0]                              m_axi_hbm_wlast,
    output wire [HBM_CH*AXI_HBM_WUSER_WIDTH-1:0]          m_axi_hbm_wuser,
    output wire [HBM_CH-1:0]                              m_axi_hbm_wvalid,
    input  wire [HBM_CH-1:0]                              m_axi_hbm_wready,
    input  wire [HBM_CH*AXI_HBM_ID_WIDTH-1:0]             m_axi_hbm_bid,
    input  wire [HBM_CH*2-1:0]                            m_axi_hbm_bresp,
    input  wire [HBM_CH*AXI_HBM_BUSER_WIDTH-1:0]          m_axi_hbm_buser,
    input  wire [HBM_CH-1:0]                              m_axi_hbm_bvalid,
    output wire [HBM_CH-1:0]                              m_axi_hbm_bready,
    output wire [HBM_CH*AXI_HBM_ID_WIDTH-1:0]             m_axi_hbm_arid,
    output wire [HBM_CH*AXI_HBM_ADDR_WIDTH-1:0]           m_axi_hbm_araddr,
    output wire [HBM_CH*8-1:0]                            m_axi_hbm_arlen,
    output wire [HBM_CH*3-1:0]                            m_axi_hbm_arsize,
    output wire [HBM_CH*2-1:0]                            m_axi_hbm_arburst,
    output wire [HBM_CH-1:0]                              m_axi_hbm_arlock,
    output wire [HBM_CH*4-1:0]                            m_axi_hbm_arcache,
    output wire [HBM_CH*3-1:0]                            m_axi_hbm_arprot,
    output wire [HBM_CH*4-1:0]                            m_axi_hbm_arqos,
    output wire [HBM_CH*AXI_HBM_ARUSER_WIDTH-1:0]         m_axi_hbm_aruser,
    output wire [HBM_CH-1:0]                              m_axi_hbm_arvalid,
    input  wire [HBM_CH-1:0]                              m_axi_hbm_arready,
    input  wire [HBM_CH*AXI_HBM_ID_WIDTH-1:0]             m_axi_hbm_rid,
    input  wire [HBM_CH*AXI_HBM_DATA_WIDTH-1:0]           m_axi_hbm_rdata,
    input  wire [HBM_CH*2-1:0]                            m_axi_hbm_rresp,
    input  wire [HBM_CH-1:0]                              m_axi_hbm_rlast,
    input  wire [HBM_CH*AXI_HBM_RUSER_WIDTH-1:0]          m_axi_hbm_ruser,
    input  wire [HBM_CH-1:0]                              m_axi_hbm_rvalid,
    output wire [HBM_CH-1:0]                              m_axi_hbm_rready,

    input  wire [HBM_CH-1:0]                              hbm_status,

    /*
     * Statistics increment output
     */
    output wire [STAT_INC_WIDTH-1:0]                      m_axis_stat_tdata,
    output wire [STAT_ID_WIDTH-1:0]                       m_axis_stat_tid,
    output wire                                           m_axis_stat_tvalid,
    input  wire                                           m_axis_stat_tready,

    /*
     * GPIO
     */
    input  wire [APP_GPIO_IN_WIDTH-1:0]                   gpio_in,
    output wire [APP_GPIO_OUT_WIDTH-1:0]                  gpio_out,

    /*
     * JTAG
     */
    input  wire                                           jtag_tdi,
    output wire                                           jtag_tdo,
    input  wire                                           jtag_tms,
    input  wire                                           jtag_tck
);

localparam REG_ADDR_WIDTH = AXIL_APP_CTRL_ADDR_WIDTH;
localparam REG_DATA_WIDTH = AXIL_APP_CTRL_DATA_WIDTH;
localparam REG_STRB_WIDTH = AXIL_APP_CTRL_STRB_WIDTH;

localparam RB_BASE_ADDR = 0;
localparam RBB = RB_BASE_ADDR & {AXIL_APP_CTRL_ADDR_WIDTH{1'b1}};

localparam DMA_BENCH_RB_BASE_ADDR = RB_BASE_ADDR;

localparam DRAM_CH_RB_BASE_ADDR = DMA_BENCH_RB_BASE_ADDR + 16'h1000;
localparam DRAM_CH_RB_STRIDE = 16'h0100;

localparam DDR_CH_OFFSET = 0;
localparam HBM_CH_OFFSET = DDR_CH_OFFSET + (DDR_ENABLE ? DDR_CH : 0);
localparam DRAM_CH_COUNT = HBM_CH_OFFSET + (HBM_ENABLE ? HBM_CH : 0);

// check configuration
initial begin
    if (APP_ID != 32'h12348001) begin
        $error("Error: Invalid APP_ID (expected 32'h12348001, got 32'h%x) (instance %m)", APP_ID);
        $finish;
    end

    if (!APP_DMA_ENABLE) begin
        $error("Error: APP_DMA_ENABLE required (instance %m)");
        $finish;
    end
end

localparam RAM_ADDR_IMM_WIDTH = (DMA_IMM_ENABLE && (DMA_IMM_WIDTH > RAM_ADDR_WIDTH)) ? DMA_IMM_WIDTH : RAM_ADDR_WIDTH;

/*
 * AXI-Lite master interface (control to NIC)
 */
assign m_axil_ctrl_awaddr = 0;
assign m_axil_ctrl_awprot = 0;
assign m_axil_ctrl_awvalid = 1'b0;
assign m_axil_ctrl_wdata = 0;
assign m_axil_ctrl_wstrb = 0;
assign m_axil_ctrl_wvalid = 1'b0;
assign m_axil_ctrl_bready = 1'b1;
assign m_axil_ctrl_araddr = 0;
assign m_axil_ctrl_arprot = 0;
assign m_axil_ctrl_arvalid = 1'b0;
assign m_axil_ctrl_rready = 1'b1;

/*
 * DMA interface (control)
 */
assign m_axis_ctrl_dma_read_desc_dma_addr = 0;
assign m_axis_ctrl_dma_read_desc_ram_sel = 0;
assign m_axis_ctrl_dma_read_desc_ram_addr = 0;
assign m_axis_ctrl_dma_read_desc_len = 0;
assign m_axis_ctrl_dma_read_desc_tag = 0;
assign m_axis_ctrl_dma_read_desc_valid = 1'b0;
assign m_axis_ctrl_dma_write_desc_dma_addr = 0;
assign m_axis_ctrl_dma_write_desc_ram_sel = 0;
assign m_axis_ctrl_dma_write_desc_ram_addr = 0;
assign m_axis_ctrl_dma_write_desc_imm = 0;
assign m_axis_ctrl_dma_write_desc_imm_en = 0;
assign m_axis_ctrl_dma_write_desc_len = 0;
assign m_axis_ctrl_dma_write_desc_tag = 0;
assign m_axis_ctrl_dma_write_desc_valid = 1'b0;

assign ctrl_dma_ram_wr_cmd_ready = 1'b1;
assign ctrl_dma_ram_wr_done = ctrl_dma_ram_wr_cmd_valid;
assign ctrl_dma_ram_rd_cmd_ready = ctrl_dma_ram_rd_resp_ready;
assign ctrl_dma_ram_rd_resp_data = 0;
assign ctrl_dma_ram_rd_resp_valid = ctrl_dma_ram_rd_cmd_valid;

/*
 * Ethernet (direct MAC interface - lowest latency raw traffic)
 */
assign m_axis_direct_tx_tdata = s_axis_direct_tx_tdata;
assign m_axis_direct_tx_tkeep = s_axis_direct_tx_tkeep;
assign m_axis_direct_tx_tvalid = s_axis_direct_tx_tvalid;
assign s_axis_direct_tx_tready = m_axis_direct_tx_tready;
assign m_axis_direct_tx_tlast = s_axis_direct_tx_tlast;
assign m_axis_direct_tx_tuser = s_axis_direct_tx_tuser;

assign m_axis_direct_tx_cpl_ts = s_axis_direct_tx_cpl_ts;
assign m_axis_direct_tx_cpl_tag = s_axis_direct_tx_cpl_tag;
assign m_axis_direct_tx_cpl_valid = s_axis_direct_tx_cpl_valid;
assign s_axis_direct_tx_cpl_ready = m_axis_direct_tx_cpl_ready;

assign m_axis_direct_rx_tdata = s_axis_direct_rx_tdata;
assign m_axis_direct_rx_tkeep = s_axis_direct_rx_tkeep;
assign m_axis_direct_rx_tvalid = s_axis_direct_rx_tvalid;
assign s_axis_direct_rx_tready = m_axis_direct_rx_tready;
assign m_axis_direct_rx_tlast = s_axis_direct_rx_tlast;
assign m_axis_direct_rx_tuser = s_axis_direct_rx_tuser;

/*
 * Ethernet (synchronous MAC interface - low latency raw traffic)
 */
assign m_axis_sync_tx_tdata = s_axis_sync_tx_tdata;
assign m_axis_sync_tx_tkeep = s_axis_sync_tx_tkeep;
assign m_axis_sync_tx_tvalid = s_axis_sync_tx_tvalid;
assign s_axis_sync_tx_tready = m_axis_sync_tx_tready;
assign m_axis_sync_tx_tlast = s_axis_sync_tx_tlast;
assign m_axis_sync_tx_tuser = s_axis_sync_tx_tuser;

assign m_axis_sync_tx_cpl_ts = s_axis_sync_tx_cpl_ts;
assign m_axis_sync_tx_cpl_tag = s_axis_sync_tx_cpl_tag;
assign m_axis_sync_tx_cpl_valid = s_axis_sync_tx_cpl_valid;
assign s_axis_sync_tx_cpl_ready = m_axis_sync_tx_cpl_ready;

assign m_axis_sync_rx_tdata = s_axis_sync_rx_tdata;
assign m_axis_sync_rx_tkeep = s_axis_sync_rx_tkeep;
assign m_axis_sync_rx_tvalid = s_axis_sync_rx_tvalid;
assign s_axis_sync_rx_tready = m_axis_sync_rx_tready;
assign m_axis_sync_rx_tlast = s_axis_sync_rx_tlast;
assign m_axis_sync_rx_tuser = s_axis_sync_rx_tuser;

/*
 * Ethernet (internal at interface module)
 */
assign m_axis_if_tx_tdata = s_axis_if_tx_tdata;
assign m_axis_if_tx_tkeep = s_axis_if_tx_tkeep;
assign m_axis_if_tx_tvalid = s_axis_if_tx_tvalid;
assign s_axis_if_tx_tready = m_axis_if_tx_tready;
assign m_axis_if_tx_tlast = s_axis_if_tx_tlast;
assign m_axis_if_tx_tid = s_axis_if_tx_tid;
assign m_axis_if_tx_tdest = s_axis_if_tx_tdest;
assign m_axis_if_tx_tuser = s_axis_if_tx_tuser;

assign m_axis_if_tx_cpl_ts = s_axis_if_tx_cpl_ts;
assign m_axis_if_tx_cpl_tag = s_axis_if_tx_cpl_tag;
assign m_axis_if_tx_cpl_valid = s_axis_if_tx_cpl_valid;
assign s_axis_if_tx_cpl_ready = m_axis_if_tx_cpl_ready;

assign m_axis_if_rx_tdata = s_axis_if_rx_tdata;
assign m_axis_if_rx_tkeep = s_axis_if_rx_tkeep;
assign m_axis_if_rx_tvalid = s_axis_if_rx_tvalid;
assign s_axis_if_rx_tready = m_axis_if_rx_tready;
assign m_axis_if_rx_tlast = s_axis_if_rx_tlast;
assign m_axis_if_rx_tid = s_axis_if_rx_tid;
assign m_axis_if_rx_tdest = s_axis_if_rx_tdest;
assign m_axis_if_rx_tuser = s_axis_if_rx_tuser;

/*
 * Statistics increment output
 */
assign m_axis_stat_tdata = 0;
assign m_axis_stat_tid = 0;
assign m_axis_stat_tvalid = 1'b0;

/*
 * GPIO
 */
assign gpio_out = 0;

/*
 * JTAG
 */
assign jtag_tdo = jtag_tdi;


// control registers
wire [REG_ADDR_WIDTH-1:0]  ctrl_reg_wr_addr;
wire [REG_DATA_WIDTH-1:0]  ctrl_reg_wr_data;
wire [REG_STRB_WIDTH-1:0]  ctrl_reg_wr_strb;
wire                       ctrl_reg_wr_en;
wire                       ctrl_reg_wr_wait;
wire                       ctrl_reg_wr_ack;
wire [REG_ADDR_WIDTH-1:0]  ctrl_reg_rd_addr;
wire                       ctrl_reg_rd_en;
wire [REG_DATA_WIDTH-1:0]  ctrl_reg_rd_data;
wire                       ctrl_reg_rd_wait;
wire                       ctrl_reg_rd_ack;

axil_reg_if #(
    .DATA_WIDTH(REG_DATA_WIDTH),
    .ADDR_WIDTH(REG_ADDR_WIDTH),
    .STRB_WIDTH(REG_STRB_WIDTH),
    .TIMEOUT(8)
)
axil_reg_if_inst (
    .clk(clk),
    .rst(rst),

    /*
     * AXI-Lite slave interface
     */
    .s_axil_awaddr(s_axil_app_ctrl_awaddr),
    .s_axil_awprot(s_axil_app_ctrl_awprot),
    .s_axil_awvalid(s_axil_app_ctrl_awvalid),
    .s_axil_awready(s_axil_app_ctrl_awready),
    .s_axil_wdata(s_axil_app_ctrl_wdata),
    .s_axil_wstrb(s_axil_app_ctrl_wstrb),
    .s_axil_wvalid(s_axil_app_ctrl_wvalid),
    .s_axil_wready(s_axil_app_ctrl_wready),
    .s_axil_bresp(s_axil_app_ctrl_bresp),
    .s_axil_bvalid(s_axil_app_ctrl_bvalid),
    .s_axil_bready(s_axil_app_ctrl_bready),
    .s_axil_araddr(s_axil_app_ctrl_araddr),
    .s_axil_arprot(s_axil_app_ctrl_arprot),
    .s_axil_arvalid(s_axil_app_ctrl_arvalid),
    .s_axil_arready(s_axil_app_ctrl_arready),
    .s_axil_rdata(s_axil_app_ctrl_rdata),
    .s_axil_rresp(s_axil_app_ctrl_rresp),
    .s_axil_rvalid(s_axil_app_ctrl_rvalid),
    .s_axil_rready(s_axil_app_ctrl_rready),

    /*
     * Register interface
     */
    .reg_wr_addr(ctrl_reg_wr_addr),
    .reg_wr_data(ctrl_reg_wr_data),
    .reg_wr_strb(ctrl_reg_wr_strb),
    .reg_wr_en(ctrl_reg_wr_en),
    .reg_wr_wait(ctrl_reg_wr_wait),
    .reg_wr_ack(ctrl_reg_wr_ack),
    .reg_rd_addr(ctrl_reg_rd_addr),
    .reg_rd_en(ctrl_reg_rd_en),
    .reg_rd_data(ctrl_reg_rd_data),
    .reg_rd_wait(ctrl_reg_rd_wait),
    .reg_rd_ack(ctrl_reg_rd_ack)
);

wire dma_bench_ctrl_reg_wr_wait;
wire dma_bench_ctrl_reg_wr_ack;
wire [REG_DATA_WIDTH-1:0] dma_bench_ctrl_reg_rd_data;
wire dma_bench_ctrl_reg_rd_wait;
wire dma_bench_ctrl_reg_rd_ack;

wire ch_ctrl_reg_wr_wait[DRAM_CH_COUNT-1:0];
wire ch_ctrl_reg_wr_ack[DRAM_CH_COUNT-1:0];
wire [REG_DATA_WIDTH-1:0] ch_ctrl_reg_rd_data[DRAM_CH_COUNT-1:0];
wire ch_ctrl_reg_rd_wait[DRAM_CH_COUNT-1:0];
wire ch_ctrl_reg_rd_ack[DRAM_CH_COUNT-1:0];

reg ctrl_reg_wr_wait_cmb;
reg ctrl_reg_wr_ack_cmb;
reg [REG_DATA_WIDTH-1:0] ctrl_reg_rd_data_cmb;
reg ctrl_reg_rd_wait_cmb;
reg ctrl_reg_rd_ack_cmb;

assign ctrl_reg_wr_wait = ctrl_reg_wr_wait_cmb;
assign ctrl_reg_wr_ack = ctrl_reg_wr_ack_cmb;
assign ctrl_reg_rd_data = ctrl_reg_rd_data_cmb;
assign ctrl_reg_rd_wait = ctrl_reg_rd_wait_cmb;
assign ctrl_reg_rd_ack = ctrl_reg_rd_ack_cmb;

integer k;

always @* begin
    ctrl_reg_wr_wait_cmb = dma_bench_ctrl_reg_wr_wait;
    ctrl_reg_wr_ack_cmb = dma_bench_ctrl_reg_wr_ack;
    ctrl_reg_rd_data_cmb = dma_bench_ctrl_reg_rd_data;
    ctrl_reg_rd_wait_cmb = dma_bench_ctrl_reg_rd_wait;
    ctrl_reg_rd_ack_cmb = dma_bench_ctrl_reg_rd_ack;

    for (k = 0; k < DRAM_CH_COUNT; k = k + 1) begin
        ctrl_reg_wr_wait_cmb = ctrl_reg_wr_wait_cmb | ch_ctrl_reg_wr_wait[k];
        ctrl_reg_wr_ack_cmb = ctrl_reg_wr_ack_cmb | ch_ctrl_reg_wr_ack[k];
        ctrl_reg_rd_data_cmb = ctrl_reg_rd_data_cmb | ch_ctrl_reg_rd_data[k];
        ctrl_reg_rd_wait_cmb = ctrl_reg_rd_wait_cmb | ch_ctrl_reg_rd_wait[k];
        ctrl_reg_rd_ack_cmb = ctrl_reg_rd_ack_cmb | ch_ctrl_reg_rd_ack[k];
    end
end

// DMA benchmark
dma_bench #(
    // DMA interface configuration
    .DMA_ADDR_WIDTH(DMA_ADDR_WIDTH),
    .DMA_IMM_ENABLE(DMA_IMM_ENABLE),
    .DMA_IMM_WIDTH(DMA_IMM_WIDTH),
    .DMA_LEN_WIDTH(DMA_LEN_WIDTH),
    .DMA_TAG_WIDTH(DMA_TAG_WIDTH),
    .RAM_SEL_WIDTH(RAM_SEL_WIDTH),
    .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
    .RAM_SEG_COUNT(RAM_SEG_COUNT),
    .RAM_SEG_DATA_WIDTH(RAM_SEG_DATA_WIDTH),
    .RAM_SEG_BE_WIDTH(RAM_SEG_BE_WIDTH),
    .RAM_SEG_ADDR_WIDTH(RAM_SEG_ADDR_WIDTH),
    .RAM_PIPELINE(RAM_PIPELINE),

    // Register interface
    .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
    .REG_DATA_WIDTH(REG_DATA_WIDTH),
    .REG_STRB_WIDTH(REG_STRB_WIDTH),
    .RB_BASE_ADDR(DMA_BENCH_RB_BASE_ADDR),
    .RB_NEXT_PTR((DDR_ENABLE || HBM_ENABLE) ? DRAM_CH_RB_BASE_ADDR : 0)
)
dma_bench_inst (
    .clk(clk),
    .rst(rst),

    /*
     * Register interface
     */
    .reg_wr_addr(ctrl_reg_wr_addr),
    .reg_wr_data(ctrl_reg_wr_data),
    .reg_wr_strb(ctrl_reg_wr_strb),
    .reg_wr_en(ctrl_reg_wr_en),
    .reg_wr_wait(dma_bench_ctrl_reg_wr_wait),
    .reg_wr_ack(dma_bench_ctrl_reg_wr_ack),
    .reg_rd_addr(ctrl_reg_rd_addr),
    .reg_rd_en(ctrl_reg_rd_en),
    .reg_rd_data(dma_bench_ctrl_reg_rd_data),
    .reg_rd_wait(dma_bench_ctrl_reg_rd_wait),
    .reg_rd_ack(dma_bench_ctrl_reg_rd_ack),

    /*
     * DMA read descriptor output
     */
    .m_axis_dma_read_desc_dma_addr(m_axis_data_dma_read_desc_dma_addr),
    .m_axis_dma_read_desc_ram_sel(m_axis_data_dma_read_desc_ram_sel),
    .m_axis_dma_read_desc_ram_addr(m_axis_data_dma_read_desc_ram_addr),
    .m_axis_dma_read_desc_len(m_axis_data_dma_read_desc_len),
    .m_axis_dma_read_desc_tag(m_axis_data_dma_read_desc_tag),
    .m_axis_dma_read_desc_valid(m_axis_data_dma_read_desc_valid),
    .m_axis_dma_read_desc_ready(m_axis_data_dma_read_desc_ready),

    /*
     * DMA read descriptor status input
     */
    .s_axis_dma_read_desc_status_tag(s_axis_data_dma_read_desc_status_tag),
    .s_axis_dma_read_desc_status_error(s_axis_data_dma_read_desc_status_error),
    .s_axis_dma_read_desc_status_valid(s_axis_data_dma_read_desc_status_valid),

    /*
     * DMA write descriptor output
     */
    .m_axis_dma_write_desc_dma_addr(m_axis_data_dma_write_desc_dma_addr),
    .m_axis_dma_write_desc_ram_sel(m_axis_data_dma_write_desc_ram_sel),
    .m_axis_dma_write_desc_ram_addr(m_axis_data_dma_write_desc_ram_addr),
    .m_axis_dma_write_desc_imm(m_axis_data_dma_write_desc_imm),
    .m_axis_dma_write_desc_imm_en(m_axis_data_dma_write_desc_imm_en),
    .m_axis_dma_write_desc_len(m_axis_data_dma_write_desc_len),
    .m_axis_dma_write_desc_tag(m_axis_data_dma_write_desc_tag),
    .m_axis_dma_write_desc_valid(m_axis_data_dma_write_desc_valid),
    .m_axis_dma_write_desc_ready(m_axis_data_dma_write_desc_ready),

    /*
     * DMA write descriptor status input
     */
    .s_axis_dma_write_desc_status_tag(s_axis_data_dma_write_desc_status_tag),
    .s_axis_dma_write_desc_status_error(s_axis_data_dma_write_desc_status_error),
    .s_axis_dma_write_desc_status_valid(s_axis_data_dma_write_desc_status_valid),

    /*
     * DMA RAM interface
     */
    .dma_ram_wr_cmd_sel(data_dma_ram_wr_cmd_sel),
    .dma_ram_wr_cmd_be(data_dma_ram_wr_cmd_be),
    .dma_ram_wr_cmd_addr(data_dma_ram_wr_cmd_addr),
    .dma_ram_wr_cmd_data(data_dma_ram_wr_cmd_data),
    .dma_ram_wr_cmd_valid(data_dma_ram_wr_cmd_valid),
    .dma_ram_wr_cmd_ready(data_dma_ram_wr_cmd_ready),
    .dma_ram_wr_done(data_dma_ram_wr_done),
    .dma_ram_rd_cmd_sel(data_dma_ram_rd_cmd_sel),
    .dma_ram_rd_cmd_addr(data_dma_ram_rd_cmd_addr),
    .dma_ram_rd_cmd_valid(data_dma_ram_rd_cmd_valid),
    .dma_ram_rd_cmd_ready(data_dma_ram_rd_cmd_ready),
    .dma_ram_rd_resp_data(data_dma_ram_rd_resp_data),
    .dma_ram_rd_resp_valid(data_dma_ram_rd_resp_valid),
    .dma_ram_rd_resp_ready(data_dma_ram_rd_resp_ready)
);

// DRAM test
generate

genvar n;

if (DDR_ENABLE) begin : ddr

    for (n = 0; n < DDR_CH; n = n + 1) begin : ddr_ch

        localparam GROUP_INDEX = n % DDR_GROUP_SIZE;
        localparam GROUP_ADDR_WIDTH = AXI_DDR_ADDR_WIDTH - $clog2(DDR_GROUP_SIZE);

        localparam BASE_ADDR = ({AXI_DDR_ADDR_WIDTH{1'b0}} | GROUP_INDEX) << GROUP_ADDR_WIDTH;
        localparam SIZE_MASK = {GROUP_ADDR_WIDTH{1'b1}};

        (* shreg_extract = "no" *)
        reg [REG_ADDR_WIDTH-1:0]  ch_reg_wr_addr_reg = 0;
        (* shreg_extract = "no" *)
        reg [REG_DATA_WIDTH-1:0]  ch_reg_wr_data_reg = 0;
        (* shreg_extract = "no" *)
        reg [REG_STRB_WIDTH-1:0]  ch_reg_wr_strb_reg = 0;
        (* shreg_extract = "no" *)
        reg                       ch_reg_wr_en_reg = 1'b0;
        (* shreg_extract = "no" *)
        reg                       ch_reg_wr_wait_reg = 1'b0;
        (* shreg_extract = "no" *)
        reg                       ch_reg_wr_ack_reg = 1'b0;
        (* shreg_extract = "no" *)
        reg [REG_ADDR_WIDTH-1:0]  ch_reg_rd_addr_reg = 0;
        (* shreg_extract = "no" *)
        reg                       ch_reg_rd_en_reg = 1'b0;
        (* shreg_extract = "no" *)
        reg [REG_DATA_WIDTH-1:0]  ch_reg_rd_data_reg = 0;
        (* shreg_extract = "no" *)
        reg                       ch_reg_rd_wait_reg = 1'b0;
        (* shreg_extract = "no" *)
        reg                       ch_reg_rd_ack_reg = 1'b0;

        wire ch_reg_wr_wait;
        wire ch_reg_wr_ack;
        wire [REG_DATA_WIDTH-1:0] ch_reg_rd_data;
        wire ch_reg_rd_wait;
        wire ch_reg_rd_ack;

        always @(posedge clk) begin
            ch_reg_wr_addr_reg <= ctrl_reg_wr_addr;
            ch_reg_wr_data_reg <= ctrl_reg_wr_data;
            ch_reg_wr_strb_reg <= ctrl_reg_wr_strb;
            ch_reg_wr_en_reg <= ctrl_reg_wr_en;
            ch_reg_wr_wait_reg <= ch_reg_wr_wait;
            ch_reg_wr_ack_reg <= ch_reg_wr_ack;
            ch_reg_rd_addr_reg <= ctrl_reg_rd_addr;
            ch_reg_rd_en_reg <= ctrl_reg_rd_en;
            ch_reg_rd_data_reg <= ch_reg_rd_data;
            ch_reg_rd_wait_reg <= ch_reg_rd_wait;
            ch_reg_rd_ack_reg <= ch_reg_rd_ack;

            if (rst) begin
                ch_reg_wr_en_reg <= 1'b0;
                ch_reg_wr_wait_reg <= 1'b0;
                ch_reg_wr_ack_reg <= 1'b0;
                ch_reg_rd_en_reg <= 1'b0;
                ch_reg_rd_wait_reg <= 1'b0;
                ch_reg_rd_ack_reg <= 1'b0;
            end
        end

        assign ch_ctrl_reg_wr_wait[DDR_CH_OFFSET+n] = ch_reg_wr_wait;
        assign ch_ctrl_reg_wr_ack[DDR_CH_OFFSET+n] = ch_reg_wr_ack;
        assign ch_ctrl_reg_rd_data[DDR_CH_OFFSET+n] = ch_reg_rd_data;
        assign ch_ctrl_reg_rd_wait[DDR_CH_OFFSET+n] = ch_reg_rd_wait;
        assign ch_ctrl_reg_rd_ack[DDR_CH_OFFSET+n] = ch_reg_rd_ack;

        dram_test_ch #(
            // AXI configuration
            .AXI_DATA_WIDTH(AXI_DDR_DATA_WIDTH),
            .AXI_ADDR_WIDTH(AXI_DDR_ADDR_WIDTH),
            .AXI_STRB_WIDTH(AXI_DDR_STRB_WIDTH),
            .AXI_ID_WIDTH(AXI_DDR_ID_WIDTH),
            .AXI_MAX_BURST_LEN(AXI_DDR_MAX_BURST_LEN),

            // FIFO config
            .FIFO_BASE_ADDR(BASE_ADDR),
            .FIFO_SIZE_MASK(SIZE_MASK),

            // Register interface
            .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
            .REG_DATA_WIDTH(REG_DATA_WIDTH),
            .REG_STRB_WIDTH(REG_STRB_WIDTH),
            .RB_BASE_ADDR(DRAM_CH_RB_BASE_ADDR + (DDR_CH_OFFSET+n)*DRAM_CH_RB_STRIDE),
            .RB_NEXT_PTR(DDR_CH_OFFSET+n < DRAM_CH_COUNT-1 ? DRAM_CH_RB_BASE_ADDR + (DDR_CH_OFFSET+n+1)*DRAM_CH_RB_STRIDE : 0)
        )
        dram_test_ch_inst (
            .clk(clk),
            .rst(rst),

            /*
             * Register interface
             */
            .reg_wr_addr(ch_reg_wr_addr_reg),
            .reg_wr_data(ch_reg_wr_data_reg),
            .reg_wr_strb(ch_reg_wr_strb_reg),
            .reg_wr_en(ch_reg_wr_en_reg),
            .reg_wr_wait(ch_reg_wr_wait),
            .reg_wr_ack(ch_reg_wr_ack),
            .reg_rd_addr(ch_reg_rd_addr_reg),
            .reg_rd_en(ch_reg_rd_en_reg),
            .reg_rd_data(ch_reg_rd_data),
            .reg_rd_wait(ch_reg_rd_wait),
            .reg_rd_ack(ch_reg_rd_ack),

            /*
             * AXI master interface
             */
            .m_axi_clk(ddr_clk[n]),
            .m_axi_rst(ddr_rst[n]),
            .m_axi_awid(m_axi_ddr_awid[n*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
            .m_axi_awaddr(m_axi_ddr_awaddr[n*AXI_DDR_ADDR_WIDTH +: AXI_DDR_ADDR_WIDTH]),
            .m_axi_awlen(m_axi_ddr_awlen[n*8 +: 8]),
            .m_axi_awsize(m_axi_ddr_awsize[n*3 +: 3]),
            .m_axi_awburst(m_axi_ddr_awburst[n*2 +: 2]),
            .m_axi_awlock(m_axi_ddr_awlock[n +: 1]),
            .m_axi_awcache(m_axi_ddr_awcache[n*4 +: 4]),
            .m_axi_awprot(m_axi_ddr_awprot[n*3 +: 3]),
            .m_axi_awvalid(m_axi_ddr_awvalid[n +: 1]),
            .m_axi_awready(m_axi_ddr_awready[n +: 1]),
            .m_axi_wdata(m_axi_ddr_wdata[n*AXI_DDR_DATA_WIDTH +: AXI_DDR_DATA_WIDTH]),
            .m_axi_wstrb(m_axi_ddr_wstrb[n*AXI_DDR_STRB_WIDTH +: AXI_DDR_STRB_WIDTH]),
            .m_axi_wlast(m_axi_ddr_wlast[n +: 1]),
            .m_axi_wvalid(m_axi_ddr_wvalid[n +: 1]),
            .m_axi_wready(m_axi_ddr_wready[n +: 1]),
            .m_axi_bid(m_axi_ddr_bid[n*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
            .m_axi_bresp(m_axi_ddr_bresp[n*2 +: 2]),
            .m_axi_bvalid(m_axi_ddr_bvalid[n +: 1]),
            .m_axi_bready(m_axi_ddr_bready[n +: 1]),
            .m_axi_arid(m_axi_ddr_arid[n*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
            .m_axi_araddr(m_axi_ddr_araddr[n*AXI_DDR_ADDR_WIDTH +: AXI_DDR_ADDR_WIDTH]),
            .m_axi_arlen(m_axi_ddr_arlen[n*8 +: 8]),
            .m_axi_arsize(m_axi_ddr_arsize[n*3 +: 3]),
            .m_axi_arburst(m_axi_ddr_arburst[n*2 +: 2]),
            .m_axi_arlock(m_axi_ddr_arlock[n +: 1]),
            .m_axi_arcache(m_axi_ddr_arcache[n*4 +: 4]),
            .m_axi_arprot(m_axi_ddr_arprot[n*3 +: 3]),
            .m_axi_arvalid(m_axi_ddr_arvalid[n +: 1]),
            .m_axi_arready(m_axi_ddr_arready[n +: 1]),
            .m_axi_rid(m_axi_ddr_rid[n*AXI_DDR_ID_WIDTH +: AXI_DDR_ID_WIDTH]),
            .m_axi_rdata(m_axi_ddr_rdata[n*AXI_DDR_DATA_WIDTH +: AXI_DDR_DATA_WIDTH]),
            .m_axi_rresp(m_axi_ddr_rresp[n*2 +: 2]),
            .m_axi_rlast(m_axi_ddr_rlast[n +: 1]),
            .m_axi_rvalid(m_axi_ddr_rvalid[n +: 1]),
            .m_axi_rready(m_axi_ddr_rready[n +: 1])
        );

    end

end else begin

    assign m_axi_ddr_awid = 0;
    assign m_axi_ddr_awaddr = 0;
    assign m_axi_ddr_awlen = 0;
    assign m_axi_ddr_awsize = 0;
    assign m_axi_ddr_awburst = 0;
    assign m_axi_ddr_awlock = 0;
    assign m_axi_ddr_awcache = 0;
    assign m_axi_ddr_awprot = 0;
    assign m_axi_ddr_awvalid = 0;
    assign m_axi_ddr_wdata = 0;
    assign m_axi_ddr_wstrb = 0;
    assign m_axi_ddr_wlast = 0;
    assign m_axi_ddr_wvalid = 0;
    assign m_axi_ddr_bready = 0;
    assign m_axi_ddr_arid = 0;
    assign m_axi_ddr_araddr = 0;
    assign m_axi_ddr_arlen = 0;
    assign m_axi_ddr_arsize = 0;
    assign m_axi_ddr_arburst = 0;
    assign m_axi_ddr_arlock = 0;
    assign m_axi_ddr_arcache = 0;
    assign m_axi_ddr_arprot = 0;
    assign m_axi_ddr_arvalid = 0;
    assign m_axi_ddr_rready = 0;

end

assign m_axi_ddr_awqos = 0;
assign m_axi_ddr_awuser = 0;
assign m_axi_ddr_wuser = 0;
assign m_axi_ddr_arqos = 0;
assign m_axi_ddr_aruser = 0;

if (HBM_ENABLE) begin : hbm

    for (n = 0; n < HBM_CH; n = n + 1) begin : hbm_ch

        localparam GROUP_INDEX = n % HBM_GROUP_SIZE;
        localparam GROUP_ADDR_WIDTH = AXI_HBM_ADDR_WIDTH - $clog2(HBM_GROUP_SIZE);

        localparam BASE_ADDR = ({AXI_HBM_ADDR_WIDTH{1'b0}} | GROUP_INDEX) << GROUP_ADDR_WIDTH;
        localparam SIZE_MASK = {GROUP_ADDR_WIDTH{1'b1}};

        (* shreg_extract = "no" *)
        reg [REG_ADDR_WIDTH-1:0]  ch_reg_wr_addr_reg = 0;
        (* shreg_extract = "no" *)
        reg [REG_DATA_WIDTH-1:0]  ch_reg_wr_data_reg = 0;
        (* shreg_extract = "no" *)
        reg [REG_STRB_WIDTH-1:0]  ch_reg_wr_strb_reg = 0;
        (* shreg_extract = "no" *)
        reg                       ch_reg_wr_en_reg = 1'b0;
        (* shreg_extract = "no" *)
        reg                       ch_reg_wr_wait_reg = 1'b0;
        (* shreg_extract = "no" *)
        reg                       ch_reg_wr_ack_reg = 1'b0;
        (* shreg_extract = "no" *)
        reg [REG_ADDR_WIDTH-1:0]  ch_reg_rd_addr_reg = 0;
        (* shreg_extract = "no" *)
        reg                       ch_reg_rd_en_reg = 1'b0;
        (* shreg_extract = "no" *)
        reg [REG_DATA_WIDTH-1:0]  ch_reg_rd_data_reg = 0;
        (* shreg_extract = "no" *)
        reg                       ch_reg_rd_wait_reg = 1'b0;
        (* shreg_extract = "no" *)
        reg                       ch_reg_rd_ack_reg = 1'b0;

        wire ch_reg_wr_wait;
        wire ch_reg_wr_ack;
        wire [REG_DATA_WIDTH-1:0] ch_reg_rd_data;
        wire ch_reg_rd_wait;
        wire ch_reg_rd_ack;

        always @(posedge clk) begin
            ch_reg_wr_addr_reg <= ctrl_reg_wr_addr;
            ch_reg_wr_data_reg <= ctrl_reg_wr_data;
            ch_reg_wr_strb_reg <= ctrl_reg_wr_strb;
            ch_reg_wr_en_reg <= ctrl_reg_wr_en;
            ch_reg_wr_wait_reg <= ch_reg_wr_wait;
            ch_reg_wr_ack_reg <= ch_reg_wr_ack;
            ch_reg_rd_addr_reg <= ctrl_reg_rd_addr;
            ch_reg_rd_en_reg <= ctrl_reg_rd_en;
            ch_reg_rd_data_reg <= ch_reg_rd_data;
            ch_reg_rd_wait_reg <= ch_reg_rd_wait;
            ch_reg_rd_ack_reg <= ch_reg_rd_ack;

            if (rst) begin
                ch_reg_wr_en_reg <= 1'b0;
                ch_reg_wr_wait_reg <= 1'b0;
                ch_reg_wr_ack_reg <= 1'b0;
                ch_reg_rd_en_reg <= 1'b0;
                ch_reg_rd_wait_reg <= 1'b0;
                ch_reg_rd_ack_reg <= 1'b0;
            end
        end

        assign ch_ctrl_reg_wr_wait[HBM_CH_OFFSET+n] = ch_reg_wr_wait;
        assign ch_ctrl_reg_wr_ack[HBM_CH_OFFSET+n] = ch_reg_wr_ack;
        assign ch_ctrl_reg_rd_data[HBM_CH_OFFSET+n] = ch_reg_rd_data;
        assign ch_ctrl_reg_rd_wait[HBM_CH_OFFSET+n] = ch_reg_rd_wait;
        assign ch_ctrl_reg_rd_ack[HBM_CH_OFFSET+n] = ch_reg_rd_ack;

        dram_test_ch #(
            // AXI configuration
            .AXI_DATA_WIDTH(AXI_HBM_DATA_WIDTH),
            .AXI_ADDR_WIDTH(AXI_HBM_ADDR_WIDTH),
            .AXI_STRB_WIDTH(AXI_HBM_STRB_WIDTH),
            .AXI_ID_WIDTH(AXI_HBM_ID_WIDTH),
            .AXI_MAX_BURST_LEN(AXI_HBM_MAX_BURST_LEN),

            // FIFO config
            .FIFO_BASE_ADDR(BASE_ADDR),
            .FIFO_SIZE_MASK(SIZE_MASK),

            // Register interface
            .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
            .REG_DATA_WIDTH(REG_DATA_WIDTH),
            .REG_STRB_WIDTH(REG_STRB_WIDTH),
            .RB_BASE_ADDR(DRAM_CH_RB_BASE_ADDR + (HBM_CH_OFFSET+n)*DRAM_CH_RB_STRIDE),
            .RB_NEXT_PTR(HBM_CH_OFFSET+n < DRAM_CH_COUNT-1 ? DRAM_CH_RB_BASE_ADDR + (HBM_CH_OFFSET+n+1)*DRAM_CH_RB_STRIDE : 0)
        )
        dram_test_ch_inst (
            .clk(clk),
            .rst(rst),

            /*
             * Register interface
             */
            .reg_wr_addr(ch_reg_wr_addr_reg),
            .reg_wr_data(ch_reg_wr_data_reg),
            .reg_wr_strb(ch_reg_wr_strb_reg),
            .reg_wr_en(ch_reg_wr_en_reg),
            .reg_wr_wait(ch_reg_wr_wait),
            .reg_wr_ack(ch_reg_wr_ack),
            .reg_rd_addr(ch_reg_rd_addr_reg),
            .reg_rd_en(ch_reg_rd_en_reg),
            .reg_rd_data(ch_reg_rd_data),
            .reg_rd_wait(ch_reg_rd_wait),
            .reg_rd_ack(ch_reg_rd_ack),

            /*
             * AXI master interface
             */
            .m_axi_clk(hbm_clk[n]),
            .m_axi_rst(hbm_rst[n]),
            .m_axi_awid(m_axi_hbm_awid[n*AXI_HBM_ID_WIDTH +: AXI_HBM_ID_WIDTH]),
            .m_axi_awaddr(m_axi_hbm_awaddr[n*AXI_HBM_ADDR_WIDTH +: AXI_HBM_ADDR_WIDTH]),
            .m_axi_awlen(m_axi_hbm_awlen[n*8 +: 8]),
            .m_axi_awsize(m_axi_hbm_awsize[n*3 +: 3]),
            .m_axi_awburst(m_axi_hbm_awburst[n*2 +: 2]),
            .m_axi_awlock(m_axi_hbm_awlock[n +: 1]),
            .m_axi_awcache(m_axi_hbm_awcache[n*4 +: 4]),
            .m_axi_awprot(m_axi_hbm_awprot[n*3 +: 3]),
            .m_axi_awvalid(m_axi_hbm_awvalid[n +: 1]),
            .m_axi_awready(m_axi_hbm_awready[n +: 1]),
            .m_axi_wdata(m_axi_hbm_wdata[n*AXI_HBM_DATA_WIDTH +: AXI_HBM_DATA_WIDTH]),
            .m_axi_wstrb(m_axi_hbm_wstrb[n*AXI_HBM_STRB_WIDTH +: AXI_HBM_STRB_WIDTH]),
            .m_axi_wlast(m_axi_hbm_wlast[n +: 1]),
            .m_axi_wvalid(m_axi_hbm_wvalid[n +: 1]),
            .m_axi_wready(m_axi_hbm_wready[n +: 1]),
            .m_axi_bid(m_axi_hbm_bid[n*AXI_HBM_ID_WIDTH +: AXI_HBM_ID_WIDTH]),
            .m_axi_bresp(m_axi_hbm_bresp[n*2 +: 2]),
            .m_axi_bvalid(m_axi_hbm_bvalid[n +: 1]),
            .m_axi_bready(m_axi_hbm_bready[n +: 1]),
            .m_axi_arid(m_axi_hbm_arid[n*AXI_HBM_ID_WIDTH +: AXI_HBM_ID_WIDTH]),
            .m_axi_araddr(m_axi_hbm_araddr[n*AXI_HBM_ADDR_WIDTH +: AXI_HBM_ADDR_WIDTH]),
            .m_axi_arlen(m_axi_hbm_arlen[n*8 +: 8]),
            .m_axi_arsize(m_axi_hbm_arsize[n*3 +: 3]),
            .m_axi_arburst(m_axi_hbm_arburst[n*2 +: 2]),
            .m_axi_arlock(m_axi_hbm_arlock[n +: 1]),
            .m_axi_arcache(m_axi_hbm_arcache[n*4 +: 4]),
            .m_axi_arprot(m_axi_hbm_arprot[n*3 +: 3]),
            .m_axi_arvalid(m_axi_hbm_arvalid[n +: 1]),
            .m_axi_arready(m_axi_hbm_arready[n +: 1]),
            .m_axi_rid(m_axi_hbm_rid[n*AXI_HBM_ID_WIDTH +: AXI_HBM_ID_WIDTH]),
            .m_axi_rdata(m_axi_hbm_rdata[n*AXI_HBM_DATA_WIDTH +: AXI_HBM_DATA_WIDTH]),
            .m_axi_rresp(m_axi_hbm_rresp[n*2 +: 2]),
            .m_axi_rlast(m_axi_hbm_rlast[n +: 1]),
            .m_axi_rvalid(m_axi_hbm_rvalid[n +: 1]),
            .m_axi_rready(m_axi_hbm_rready[n +: 1])
        );

    end

end else begin

    assign m_axi_hbm_awid = 0;
    assign m_axi_hbm_awaddr = 0;
    assign m_axi_hbm_awlen = 0;
    assign m_axi_hbm_awsize = 0;
    assign m_axi_hbm_awburst = 0;
    assign m_axi_hbm_awlock = 0;
    assign m_axi_hbm_awcache = 0;
    assign m_axi_hbm_awprot = 0;
    assign m_axi_hbm_awvalid = 0;
    assign m_axi_hbm_wdata = 0;
    assign m_axi_hbm_wstrb = 0;
    assign m_axi_hbm_wlast = 0;
    assign m_axi_hbm_wvalid = 0;
    assign m_axi_hbm_bready = 0;
    assign m_axi_hbm_arid = 0;
    assign m_axi_hbm_araddr = 0;
    assign m_axi_hbm_arlen = 0;
    assign m_axi_hbm_arsize = 0;
    assign m_axi_hbm_arburst = 0;
    assign m_axi_hbm_arlock = 0;
    assign m_axi_hbm_arcache = 0;
    assign m_axi_hbm_arprot = 0;
    assign m_axi_hbm_arvalid = 0;
    assign m_axi_hbm_rready = 0;

end

assign m_axi_hbm_awqos = 0;
assign m_axi_hbm_awuser = 0;
assign m_axi_hbm_wuser = 0;
assign m_axi_hbm_arqos = 0;
assign m_axi_hbm_aruser = 0;

endgenerate

endmodule

`resetall
