# Define target platform.
PLATFORM=omap3530

# The installation directory of the DVSDK.
DVSDK_INSTALL_DIR=$(HOME)/ti/dvsdk/dvsdk_3_01_00_10

# For backwards compatibility
DVEVM_INSTALL_DIR=$(DVSDK_INSTALL_DIR)

# Where DSP/BIOS is installed.
BIOS_INSTALL_DIR=$(DVSDK_INSTALL_DIR)/bios_5_41_00_06

# Where the DSPBIOS Utils package is installed.
BIOSUTILS_INSTALL_DIR=$(DVSDK_INSTALL_DIR)/biosutils_1_02_02

# Where the Codec Engine package is installed.
CE_INSTALL_DIR=$(DVSDK_INSTALL_DIR)/codec_engine_2_25_02_11

# Where the TI C6x codegen tool is installed.
CODEGEN_INSTALL_DIR=$(HOME)/ti/TI_CGT_C6000_6.1.12


# Where the DSP Link package is installed.
LINK_INSTALL_DIR=$(DVSDK_INSTALL_DIR)/dsplink_linux_1_65_00_02

# Where DMAI package is installed.
DMAI_INSTALL_DIR=$(DVSDK_INSTALL_DIR)/dmai_2_05_00_12

# Where the DVSDK demos are installed
DEMO_INSTALL_DIR=$(DVSDK_INSTALL_DIR)/dvsdk_demos_3_01_00_13

# Where the DVTB package is installed.
DVTB_INSTALL_DIR=$(DVSDK_INSTALL_DIR)/dvtb_4_20_05

# Where the EDMA3 LLD package is installed.
EDMA3_LLD_INSTALL_DIR=$(DVSDK_INSTALL_DIR)/edma3_lld_01_11_00_03

# Where the Framework Components package is installed.
FC_INSTALL_DIR=$(DVSDK_INSTALL_DIR)/framework_components_2_25_01_05

# Where the linuxlibs package is installed.
LINUXLIBS_INSTALL_DIR=$(DVSDK_INSTALL_DIR)/linuxlibs_3_01

# Where the MFC Linux Utils package is installed.
LINUXUTILS_INSTALL_DIR=$(DVSDK_INSTALL_DIR)/linuxutils_2_26_01_02
CMEM_INSTALL_DIR=$(LINUXUTILS_INSTALL_DIR)

# Where the local power manager package is installed.
LPM_INSTALL_DIR=$(DVSDK_INSTALL_DIR)/local_power_manager_linux_1_24_02_09

ifeq ($(PLATFORM),omap3530)
# Where the cs1omap3530 codec server package is installed.
CODEC_INSTALL_DIR=$(HOME)/ti/dvsdk/dvsdk_3_01_00_10/cs1omap3530_1_01_00
endif

# Where the XDAIS package is installed.
XDAIS_INSTALL_DIR=$(DVSDK_INSTALL_DIR)/xdais_6_25_02_11

# Where the RTSC tools package is installed.
XDC_INSTALL_DIR=$(DVSDK_INSTALL_DIR)/xdctools_3_16_01_27


# The directory that points to codec engine example
USER_XDC_PATH=$(CE_INSTALL_DIR)/examples

# The directory that points to your OMAP35xx SDK installation directory.
OMAP3503_SDK_INSTALL_DIR=$(HOME)/ti/AM35x-OMAP35x-PSP-SDK-03.00.01.06

# The directory that points to your kernel source directory.
LINUXKERNEL_INSTALL_DIR=$(HOME)/linux-2.6

# The directory that points to your U-boot source directory.
UBOOT_INSTALL_DIR=$(HOME)/ti/AM35x-OMAP35x-PSP-SDK-03.00.01.06/src/u-boot/u-boot-03.00.01.06

# The prefix to be added before the GNU compiler tools (optionally including # path), i.e. "arm-linux-gnueabi-" or "/opt/bin/arm-linux-gnueabi-".
CSTOOL_DIR=$(HOME)/ti/xdir
CSTOOL_PREFIX=$(CSTOOL_DIR)/bin/arm-linux-gnueabi-

MVTOOL_DIR=$(CSTOOL_DIR)
MVTOOL_PREFIX=$(CSTOOL_PREFIX)

# Where to copy the resulting executables
EXEC_DIR=$(HOME)/ti/workdir/filesys/opt/dvsdk/$(PLATFORM)