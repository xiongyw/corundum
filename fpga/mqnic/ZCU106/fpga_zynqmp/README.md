# Corundum mqnic for ZCU106 (Zynq MPSoC PS host)

## Introduction

This design targets the Xilinx ZCU106 FPGA board. The host system of the NIC is
the Zynq US+ MPSoC.

* FPGA: xczu7ev-ffvc1156-2-e
* PHY: 10G BASE-R PHY IP core and internal GTH transceiver
* RAM: 2 GB DDR4 2400 (256M x64)

## Quick start for Ubuntu

### Build FPGA bitstream

Run `make app` in the `fpga` subdirectory to build the bitstream, `.xsa` file, and device tree overlay.  Ensure that the Xilinx Vivado toolchain components are in PATH (source `settings64.sh` in Vivado installation directory).

### Installation

Download an Ubuntu image for the ZCU106 here: https://ubuntu.com/download/amd-xilinx.  Write the image to an SD card with `dd`, for example:

	xzcat ubuntu.img.xz | dd of=/dev/sdX

Copy files in `fpga/app` to `/lib/firmware/xilinx/mqnic` on the ZCU106.  Also make a copy of the source repo on the ZCU106 from which the kernel module and userspace tools can be built.

### Build driver and userspace tools

On the ZCU106, run `make` in `modules/mqnic` to build the driver.  Ensure the headers for the running kernel are installed, otherwise the driver cannot be compiled.  Then run `make` in `utils` to build the userspace tools.

### Testing

On the ZCU106, run `sudo xmutil unloadapp` to unload the FPGA, then `sudo xmutil loadapp mqnic` to load the configuration.  Then, build the kernel module and userspace tools by running `make` in `modules/mqnic` and `utils`.  Finally, load the kernel module with `insmod mqnic.ko`.  Check `dmesg` for output from driver initialization.  Run `mqnic-dump -d /dev/mqnic0` to dump the internal state.

## Quick start for PetaLinux

### Build FPGA bitstream

Run `make` in the `fpga` subdirectory to build the bitstream and the `.xsa`
file.  Ensure that the Xilinx Vivado toolchain components are in PATH (source `settings64.sh` in Vivado installation directory).

### Build PetaLinux image

Then change into sub-directory `ps/petalinux/` and build the PetaLinux project.  Ensure that the Xilinx PetaLinux toolchain components are in PATH.

	make -C ps/petalinux/ build-boot

### Testing

Configure DIP switches:

* SW6 4-1: off, off, off, on (mode 0b1110, SD boot)

Copy the following, resulting files of building the PetaLinux project onto an SDcard suitable for then booting the ZCU106 in SDcard boot mode.

	ps/petalinux/images/linux/:
		BOOT.BIN
		boot.scr
		Image
		system.dtb
		rootfs.cpio.gz.u-boot
