# Corundum mqnic for ZCU106 (PCIe host)

## Introduction

This design targets the Xilinx ZCU106 FPGA board. The host system of the NIC is
an external host computer connected via PCIe.

* FPGA: xczu7ev-ffvc1156-2-e
* PHY: 10G BASE-R PHY IP core and internal GTH transceiver
* RAM: 2 GB DDR4 2400 (256M x64)

## Quick start

### Build FPGA bitstream

Run `make` in the `fpga` subdirectory to build the bitstream.  Ensure that the Xilinx Vivado toolchain components are in PATH.

### Build driver and userspace tools

On the host system, run `make` in `modules/mqnic` to build the driver.  Ensure the headers for the running kernel are installed, otherwise the driver cannot be compiled.  Then, run `make` in `utils` to build the userspace tools.

### Testing

Configure DIP switches:

* SW6 4-1: on, on, on, on (mode 0b0000, JTAG boot)

Run `make program` to program the board with Vivado.  Then, reboot the machine to re-enumerate the PCIe bus.  Finally, load the driver on the host system with `insmod mqnic.ko`.  Check `dmesg` for output from driver initialization, and run `mqnic-dump -d /dev/mqnic0` to dump the internal state.
