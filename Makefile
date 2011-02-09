include Rules.make

COMPONENTS:=$(DMAI_INSTALL_DIR) $(XDAIS_INSTALL_DIR) $(LINUXUTILS_INSTALL_DIR) $(EDMA3_LLD_INSTALL_DIR) $(FC_INSTALL_DIR) $(CE_INSTALL_DIR) $(XDC_INSTALL_DIR) $(BIOS_INSTALL_DIR) $(CODEC_INSTALL_DIR)

.PHONY:	all clean everything clobber help cmem cmem_clean dmai dmai_clean dmai_install demos demos_clean examples examples_clean dvtb dvtb_clean dmammapk dmammapk_clean dsplink dsplink_arm dsplink_dsp dsplink_samples dsplink_clean codecs codecs_clean linux linux_clean psp_examples psp_clean lpm lpm_clean sdma sdma_clean info check install

#==============================================================================
# Set up platform dependent variables.
#==============================================================================
ifeq ($(PLATFORM),dm6446)
COMPONENTS+=$(BIOSUTILS_INSTALL_DIR) $(LINK_INSTALL_DIR)
CHECKLIST:=$(CODEGEN_INSTALL_DIR)/bin/cl6x
REPOSITORIES:=$(DVTB_INSTALL_DIR)/packages
LINUXKERNEL_CONFIG=davinci_dm644x_defconfig
LINUXSAMPLES_PLATFORM=dm644x
DSPLINK_CONFIG=--platform=DAVINCI --nodsp=1 --dspcfg_0=DM6446GEMSHMEM --dspos_0=DSPBIOS5XX --gppos=MVL5G --comps=ponslrm
DSPLINK_MODULE=$(LINK_INSTALL_DIR)/dsplink/gpp/export/BIN/Linux/DAVINCI/RELEASE/dsplinkk.ko
HAS_SERVER=true
HAS_DSPLINK=true
HAS_IRQK=false
HAS_EDMAK=false
HAS_LPM=false
HAS_SDMA=false
OVERRIDE_KERNBIN=true
BUILD_UBOOT=false
DMAI_PLATFORM=dm6446_al
else
ifeq ($(PLATFORM),dm6467)
COMPONENTS+=$(BIOSUTILS_INSTALL_DIR) $(LINK_INSTALL_DIR)
CHECKLIST:=$(CODEGEN_INSTALL_DIR)/bin/cl6x
REPOSITORIES:=$(DVTB_INSTALL_DIR)/packages
LINUXKERNEL_CONFIG=davinci_dm646x_1ghz_defconfig
LINUXSAMPLES_PLATFORM=dm646x
DSPLINK_CONFIG=--platform=DAVINCIHD --nodsp=1 --dspcfg_0=DM6467GEMSHMEM --dspos_0=DSPBIOS5XX --gppos=DM6467LSP --comps=ponslrm
DSPLINK_MODULE=$(LINK_INSTALL_DIR)/dsplink/gpp/export/BIN/Linux/DAVINCIHD/RELEASE/dsplinkk.ko
HAS_SERVER=true
HAS_DSPLINK=true
HAS_IRQK=false
HAS_EDMAK=false
HAS_LPM=false
HAS_SDMA=false
OVERRIDE_KERNBIN=true
BUILD_UBOOT=false
DMAI_PLATFORM=dm6467_al
else
ifeq ($(PLATFORM),dm355)
REPOSITORIES:=$(DVTB_INSTALL_DIR)/packages
LINUXKERNEL_CONFIG=davinci_dm355_defconfig
LINUXSAMPLES_PLATFORM=dm355
HAS_SERVER=false
HAS_DSPLINK=false
HAS_IRQK=true
HAS_EDMAK=true
HAS_LPM=false
HAS_SDMA=false
DMAMMAP_INSTALL_DIR=$(CODEC_INSTALL_DIR)/dm355mm/module
OVERRIDE_KERNBIN=true
BUILD_UBOOT=false
DMAI_PLATFORM=dm355_al
else
ifeq ($(PLATFORM),dm365)
REPOSITORIES:=$(DVTB_INSTALL_DIR)
LINUXKERNEL_CONFIG=davinci_dm365_defconfig
LINUXSAMPLES_PLATFORM=dm365
HAS_SERVER=false
HAS_DSPLINK=false
HAS_IRQK=true
HAS_EDMAK=true
HAS_LPM=false
HAS_SDMA=false
DMAMMAP_INSTALL_DIR=$(DM365MMAP_INSTALL_DIR)/module
OVERRIDE_KERNBIN=true
BUILD_UBOOT=false
DMAI_PLATFORM=dm365_al
else
ifeq ($(PLATFORM),omap3530)
COMPONENTS+= $(LPM_INSTALL_DIR) $(BIOSUTILS_INSTALL_DIR) $(LINK_INSTALL_DIR) $(CMEM_INSTALL_DIR)
CHECKLIST:=$(CODEGEN_INSTALL_DIR)/bin/cl6x $(UBOOT_INSTALL_DIR)/doc
REPOSITORIES:=$(DVTB_INSTALL_DIR)/packages
LINUXKERNEL_CONFIG=omap3_defconfig
UBOOT_CONFIG=omap3_overo_config
LINUXSAMPLES_PLATFORM=omap3530
DSPLINK_CONFIG=--platform=OMAP3530 --nodsp=1 --dspcfg_0=OMAP3530SHMEM --dspos_0=DSPBIOS5XX --gppos=OMAPLSP --comps=ponslrmc
DSPLINK_MODULE=$(LINK_INSTALL_DIR)/packages/dsplink/gpp/export/BIN/Linux/OMAP3530/RELEASE/dsplinkk.ko
HAS_SERVER=true
HAS_DSPLINK=true
HAS_IRQK=false
HAS_EDMAK=false
HAS_LPM=true
HAS_SDMA=true
OVERRIDE_KERNBIN=false
BUILD_UBOOT=true
DMAI_PLATFORM=o3530_al
else
	$(error PLATFORM not set correctly: $(PLATFORM))
endif
endif
endif
endif
endif

REPOSITORIES+=$(addsuffix /packages, $(filter-out  $(LINK_INSTALL_DIR), $(COMPONENTS)))

CHECKLIST+=$(REPOSITORIES) $(MVTOOL_PREFIX)gcc $(LINUXKERNEL_INSTALL_DIR)/Documentation $(DEMO_INSTALL_DIR)/$(PLATFORM)
#==============================================================================
# The default build target.
#==============================================================================
all:	check cmem sdma lpm dmammapk edmak irqk dmai demos dvtb
#       examples 

#==============================================================================
# Clean up the targets built by 'make all'.
#==============================================================================
clean:	cmem_clean sdma_clean lpm_clean dmammapk_clean edmak_clean irqk_clean dmai_clean demos_clean dvtb_clean
#	examples_clean 

#==============================================================================
# Build everything rebuildable.
#==============================================================================
everything: check linux psp_examples dsplink codecs all ce_examples 

#==============================================================================
# Clean up all targets.
#==============================================================================
clobber:    clean dsplink_clean linux_clean codecs_clean psp_clean ce_examples_clean 

#==============================================================================
# A help message target.
#==============================================================================
help:
	@echo
	@echo "Available build targets are:"
	@echo
	@echo "    check           : Make sure Rules.make is set up properly"
	@echo "    info            : List versions of DVSDK components"
	@echo
	@echo "    all             : Build the components below"
	@echo "    clean           : Remove files generated by the 'all' target"
	@echo
	@echo "    cmem            : Build the CMEM kernel module for $(PLATFORM)"
	@echo "    cmem_clean      : Remove generated cmem files."
	@echo
	@echo "    dmai            : Build DMAI for $(PLATFORM)_al"
	@echo "    dmai_clean      : Remove generated DMAI files."
ifeq ($(HAS_LPM),true)
	@echo
	@echo "    lpm             : Build LPM for $(PLATFORM)"
	@echo "    lpm_clean       : Remove generated lpm files."
endif
ifeq ($(HAS_SDMA),true)
	@echo
	@echo "    sdma             : Build SDMA for $(PLATFORM)"
	@echo "    sdma_clean       : Remove generated SDMA files."
endif
	@echo
	@echo "    demos           : Build the DVSDK demos for $(PLATFORM)"
	@echo "    demos_clean     : Remove generated DVSDK demo files."
	@echo
#	@echo "    examples        : Build examples for $(PLATFORM)"
#	@echo "    examples_clean  : Build examples for $(PLATFORM)"
	@echo
	@echo "    dvtb            : Build DVTB for $(PLATFORM)"
	@echo "    dvtb_clean      : Remove generated DVTB files"
ifneq ($(DMAMMAP_INSTALL_DIR),)
	@echo
	@echo "    dmammapk        : Build the DMA MMAP kernel module"
	@echo "    dmammapk_clean  : Remove generated DMA MMAP files"
endif
ifeq ($(HAS_EDMAK),true)
	@echo
	@echo "    edmak           : Build the EDMA kernel module"
	@echo "    edmak_clean     : Remove generated EDMA files"
endif
ifeq ($(HAS_IRQK),true)
	@echo
	@echo "    irqk            : Build the IRQ kernel module"
	@echo "    irqk_clean      : Remove generated IRQ files"
endif
	@echo
	@echo "The following targets have to be explicitly built and cleaned:"
	@echo
	@echo "    everything      : Rebuild everything including below targets"
ifeq ($(HAS_DSPLINK),true)
	@echo "                      	Note: C6000 code gen tools are required"
endif
	@echo "    clobber         : Remove all generated files"
ifeq ($(HAS_DSPLINK),true)
	@echo "                      	Note: C6000 code gen tools are required"
endif
ifeq ($(HAS_DSPLINK),true)
	@echo
	@echo "    dsplink         : Configure and build DSP Link for $(PLATFORM) ARM and DSP"
	@echo "                      	Note: C6000 code gen tools are required"
	@echo "    dsplink_arm     : Configure and build DSP Link for $(PLATFORM) ARM"
	@echo "    dsplink_dsp     : Configure and build DSP Link for $(PLATFORM) DSP"
	@echo "                      	Note: C6000 code gen tools are required"
	@echo "    dsplink_samples : Build DSP Link ARM and DSP sample applications for $(PLATFORM)"
	@echo "                      	Note: C6000 code gen tools are required"
	@echo "    dsplink_clean   : Remove generated DSP Link files"
	@echo "                      	Note: C6000 code gen tools are required"
endif
ifeq ($(HAS_SERVER),true)
	@echo
	@echo "    codecs          : Build codec servers for $(PLATFORM)"
	@echo "    codecs_clean    : Remove generated codec server files"
endif
ifeq ($(BUILD_UBOOT),true)
	@echo
	@echo "    uboot           : Build uboot for $(PLATFORM)"
	@echo "    uboot_clean     : Remove generated uboot files"
endif
	@echo
	@echo "    linux           : Build Linux kernel uImage for $(PLATFORM)"
	@echo "    linux_clean     : Remove generated Linux kernel files"
	@echo
	@echo "    install         : Install binaries to $(EXEC_DIR)"
	@echo "    dmai_install    : Install DMAI binaries to $(EXEC_DIR)"
	@echo
	@echo "    ce_examples     : Build Codec Engine Examples for $(PLATFORM)"
ifeq ($(HAS_SERVER),true)
	@echo "                      	Note: C6000 code gen tools are required"
endif
	@echo "    ce_examples_clean:Remove Codec Engine Examples"
ifeq ($(HAS_SERVER),true)
	@echo "                      	Note: C6000 code gen tools are required"
endif
	@echo

#==============================================================================
# Target for listing information about the DVSDK components.
#==============================================================================
info:	check
	@LINUXKERNEL_INSTALL_DIR="$(LINUXKERNEL_INSTALL_DIR)" CODEGEN_INSTALL_DIR="$(CODEGEN_INSTALL_DIR)" GCC_PREFIX="$(MVTOOL_PREFIX)" XDC_INSTALL_DIR="$(XDC_INSTALL_DIR)" REPOSITORIES="$(REPOSITORIES)" $(DVSDK_INSTALL_DIR)/bin/info.sh

#==============================================================================
# Target for checking that the Rules.make file is set up properly.
#==============================================================================
check:
	@CHECKLIST="$(CHECKLIST)" $(DVSDK_INSTALL_DIR)/bin/check.sh

#==============================================================================
# Build the dvsdk demos for the configured platform. Also, an explicit cleanup
# target is defined.
#==============================================================================
demos:
	$(MAKE) -C $(DEMO_INSTALL_DIR) $(PLATFORM) DVSDK_INSTALL_DIR=$(DVSDK_INSTALL_DIR) XDC_INSTALL_DIR=$(XDC_INSTALL_DIR) CE_INSTALL_DIR=$(CE_INSTALL_DIR) FC_INSTALL_DIR=$(FC_INSTALL_DIR) CMEM_INSTALL_DIR=$(CMEM_INSTALL_DIR) CODEC_INSTALL_DIR=$(CODEC_INSTALL_DIR) XDAIS_INSTALL_DIR=$(XDAIS_INSTALL_DIR) LINK_INSTALL_DIR=$(LINK_INSTALL_DIR) DMAI_INSTALL_DIR=$(DMAI_INSTALL_DIR) MVTOOL_DIR=$(MVTOOL_DIR) CC=$(CSTOOL_PREFIX)gcc AR=$(CSTOOL_PREFIX)ar CROSS_COMPILE=$(MVTOOL_PREFIX) LINUXLIBS_INSTALL_DIR=$(LINUXLIBS_INSTALL_DIR) PLATFORM=$(PLATFORM)

demos_clean:
	$(MAKE) -C $(DEMO_INSTALL_DIR) clean DVSDK_INSTALL_DIR=$(DVSDK_INSTALL_DIR) XDC_INSTALL_DIR=$(XDC_INSTALL_DIR) CE_INSTALL_DIR=$(CE_INSTALL_DIR) FC_INSTALL_DIR=$(FC_INSTALL_DIR) CMEM_INSTALL_DIR=$(CMEM_INSTALL_DIR) CODEC_INSTALL_DIR=$(CODEC_INSTALL_DIR) XDAIS_INSTALL_DIR=$(XDAIS_INSTALL_DIR) LINK_INSTALL_DIR=$(LINK_INSTALL_DIR) DMAI_INSTALL_DIR=$(DMAI_INSTALL_DIR) MVTOOL_DIR=$(MVTOOL_DIR) CC=$(CSTOOL_PREFIX)gcc CROSS_COMPILE=$(MVTOOL_PREFIX) LINUXLIBS_INSTALL_DIR=$(LINUXLIBS_INSTALL_DIR) PLATFORM=$(PLATFORM)

#==============================================================================
# Build LPM for the configured platform. Also, an explicit cleanup
# target is defined.
#==============================================================================
lpm:
ifeq ($(HAS_LPM),true)
	$(MAKE) -C $(LPM_INSTALL_DIR)/packages/ti/bios/power/modules/omap3530/lpm \
                LINUXKERNEL_INSTALL_DIR=$(LINUXKERNEL_INSTALL_DIR) \
                MVTOOL_PREFIX=$(CSTOOL_PREFIX) \
                DSPLINK_REPO=$(LINK_INSTALL_DIR)/packages
endif

lpm_clean:
ifeq ($(HAS_LPM),true)
	$(MAKE)  -C $(LPM_INSTALL_DIR)/packages/ti/bios/power/modules/omap3530/lpm \
                 LINUXKERNEL_INSTALL_DIR=$(LINUXKERNEL_INSTALL_DIR) MVTOOL_PREFIX=$(CSTOOL_PREFIX) \
                 DSPLINK_REPO=$(LINK_INSTALL_DIR)/packages clean
endif
#==============================================================================

#==============================================================================
# Build the Digital Video Test Bench for the configured platform. Also, an
# explicit cleanup target is defined.
#==============================================================================
dvtb:
	$(MAKE) -C $(DVTB_INSTALL_DIR) $(PLATFORM) CODECS=TSPA
	@echo
	@echo "dvtb can be found under $(DVTB_INSTALL_DIR)/packages/ti/sdo/dvtb/$(PLATFORM)/linux/bin"

dvtb_clean:
	$(MAKE) -C $(DVTB_INSTALL_DIR) clean

#==============================================================================
# Build the uboot. Also, an explicit cleanup target is defined.
#==============================================================================
uboot:
	$(MAKE) -C $(UBOOT_INSTALL_DIR) CROSS_COMPILE=$(MVTOOL_PREFIX) $(UBOOT_CONFIG)
	$(MAKE) -C $(UBOOT_INSTALL_DIR) CROSS_COMPILE=$(MVTOOL_PREFIX)

uboot_clean:
	$(MAKE) -C $(UBOOT_INSTALL_DIR) CROSS_COMPILE=$(MVTOOL_PREFIX) distclean

#==============================================================================
# Build the Linux kernel. Also, an explicit cleanup target is defined.
#==============================================================================
ifeq ($(PLATFORM),omap3530)
linux: uboot
	$(MAKE) -C $(LINUXKERNEL_INSTALL_DIR) ARCH=arm CROSS_COMPILE=$(MVTOOL_PREFIX) $(LINUXKERNEL_CONFIG)
	$(MAKE) -C $(LINUXKERNEL_INSTALL_DIR) ARCH=arm CROSS_COMPILE=$(MVTOOL_PREFIX) PATH=$(UBOOT_INSTALL_DIR)/tools:$(PATH) uImage modules
	@echo
	@echo "Your kernel image can be found at $(LINUXKERNEL_INSTALL_DIR)/arch/arm/boot/uImage"
else
linux:
	$(MAKE) -C $(LINUXKERNEL_INSTALL_DIR) CROSS_COMPILE=$(MVTOOL_PREFIX) $(LINUXKERNEL_CONFIG)
	$(MAKE) -C $(LINUXKERNEL_INSTALL_DIR) CROSS_COMPILE=$(MVTOOL_PREFIX) uImage
	@echo
	@echo "Your kernel image can be found at $(LINUXKERNEL_INSTALL_DIR)/arch/arm/boot/uImage"
endif

ifeq ($(PLATFORM),omap3530)
linux_clean: uboot_clean
	$(MAKE) -C $(LINUXKERNEL_INSTALL_DIR) CROSS_COMPILE=$(MVTOOL_PREFIX) clean
else
linux_clean:
	$(MAKE) -C $(LINUXKERNEL_INSTALL_DIR) mrproper
#	$(MAKE) -C $(LINUXKERNEL_INSTALL_DIR) CROSS_COMPILE=$(MVTOOL_PREFIX) clean
endif

#==============================================================================
# Build the PSP Linux examples. Also, an explicit cleanup target is defined.
#==============================================================================
ifeq ($(PLATFORM),omap3530)
psp_examples:
	$(MAKE) -C $(OMAP3503_SDK_INSTALL_DIR)/src/examples/video  PLAT=omap3530 KERNEL_DIR=$(LINUXKERNEL_INSTALL_DIR) CROSS_COMPILE=$(MVTOOL_PREFIX)
	$(MAKE) -C $(OMAP3503_SDK_INSTALL_DIR)/src/examples/audio  KERNEL_DIR=$(LINUXKERNEL_INSTALL_DIR) CROSS_COMPILE=$(MVTOOL_PREFIX) LIB_INC=$(LINUXLIBS_INSTALL_DIR)/include LIB_DIR=$(LINUXLIBS_INSTALL_DIR)/lib

	@echo
	@echo "PSP examples can be found under $(OMAP3503_SDK_INSTALL_DIR)/src/examples/"
else
psp_examples:
	$(MAKE) -C $(PSP_INSTALL_DIR)/examples PLATFORM=$(LINUXSAMPLES_PLATFORM) LINUXKERNEL_INSTALL_DIR=$(LINUXKERNEL_INSTALL_DIR) CROSS_COMPILE=$(MVTOOL_PREFIX)
	@echo
	@echo "PSP examples can be found under $(PSP_INSTALL_DIR)/examples/$(LINUXSAMPLES_PLATFORM)"
endif

ifeq ($(PLATFORM),omap3530)
psp_clean:
	$(MAKE) -C $(OMAP3503_SDK_INSTALL_DIR)/src/examples/video  KERNEL_DIR=$(LINUXKERNEL_INSTALL_DIR) clean
	$(MAKE) -C $(OMAP3503_SDK_INSTALL_DIR)/src/examples/audio  KERNEL_DIR=$(LINUXKERNEL_INSTALL_DIR) clean
else
psp_clean:
	$(MAKE) -C $(PSP_INSTALL_DIR)/examples PLATFORM=$(LINUXSAMPLES_PLATFORM) LINUXKERNEL_INSTALL_DIR=$(LINUXKERNEL_INSTALL_DIR) clean
endif

#==============================================================================
# Build the CE examples. Also, an explicit cleanup target is defined.
#==============================================================================
ce_examples:
ifeq ($(HAS_SERVER),true)
	$(MAKE) -C $(CE_INSTALL_DIR)/examples/ti/sdo/ce/examples/servers DEVICES=OMAP3530 CE_EXAMPLES_INSTALL_DIR=$(CE_INSTALL_DIR)/examples/ti/sdo/ce/examples GPPOS=LINUX_GCC CE_INSTALL_DIR=$(CE_INSTALL_DIR) BIOS_INSTALL_DIR=$(BIOS_INSTALL_DIR) XDC_INSTALL_DIR=$(XDC_INSTALL_DIR) CGTOOLS_V5T=$(MVTOOL_DIR) DSPLINK_INSTALL_DIR=$(LINK_INSTALL_DIR)/packages CGTOOLS_C64P=$(CODEGEN_INSTALL_DIR) BIOSUTILS_INSTALL_DIR=$(BIOSUTILS_INSTALL_DIR) BIOS_INSTALL_DIR=$(BIOS_INSTALL_DIR)
endif
	$(MAKE) -C $(CE_INSTALL_DIR)/examples/ti/sdo/ce/examples/apps DEVICES=OMAP3530 CE_EXAMPLES_INSTALL_DIR=$(CE_INSTALL_DIR)/examples/ti/sdo/ce/examples GPPOS=LINUX_GCC CE_INSTALL_DIR=$(CE_INSTALL_DIR) BIOS_INSTALL_DIR=$(BIOS_INSTALL_DIR) XDC_INSTALL_DIR=$(XDC_INSTALL_DIR) CGTOOLS_V5T=$(MVTOOL_DIR) DSPLINK_INSTALL_DIR=$(LINK_INSTALL_DIR)/packages CGTOOLS_C64P=$(CODEGEN_INSTALL_DIR) BIOSUTILS_INSTALL_DIR=$(BIOSUTILS_INSTALL_DIR) BIOS_INSTALL_DIR=$(BIOS_INSTALL_DIR)
	@echo
	@echo "CE examples can be found under $(CE_INSTALL_DIR)/examples/ti/sdo/ce/examples"

ce_examples_clean:
ifeq ($(HAS_SERVER),true)
	$(MAKE) -C $(CE_INSTALL_DIR)/examples/ti/sdo/ce/examples/servers DEVICES=OMAP3530 CE_EXAMPLES_INSTALL_DIR=$(CE_INSTALL_DIR)/examples/ti/sdo/ce/examples GPPOS=LINUX_GCC CE_INSTALL_DIR=$(CE_INSTALL_DIR) BIOS_INSTALL_DIR=$(BIOS_INSTALL_DIR) XDC_INSTALL_DIR=$(XDC_INSTALL_DIR) CGTOOLS_V5T=$(MVTOOL_DIR) DSPLINK_INSTALL_DIR=$(LINK_INSTALL_DIR)/packages CGTOOLS_C64P=$(CODEGEN_INSTALL_DIR) BIOSUTILS_INSTALL_DIR=$(BIOSUTILS_INSTALL_DIR) BIOS_INSTALL_DIR=$(BIOS_INSTALL_DIR) clean
endif
	$(MAKE) -C $(CE_INSTALL_DIR)/examples/ti/sdo/ce/examples/apps DEVICES=OMAP3530 CE_EXAMPLES_INSTALL_DIR=$(CE_INSTALL_DIR)/examples/ti/sdo/ce/examples CROSS_COMPILE=$(MVTOOL_PREFIX) GPPOS=LINUX_GCC CE_INSTALL_DIR=$(CE_INSTALL_DIR) BIOS_INSTALL_DIR=$(BIOS_INSTALL_DIR) XDC_INSTALL_DIR=$(XDC_INSTALL_DIR)  CGTOOLS_V5T=$(MVTOOL_DIR) DSPLINK_INSTALL_DIR=$(LINK_INSTALL_DIR)/packages CGTOOLS_C64P=$(CODEGEN_INSTALL_DIR) BIOSUTILS_INSTALL_DIR=$(BIOSUTILS_INSTALL_DIR) BIOS_INSTALL_DIR=$(BIOS_INSTALL_DIR) clean

#==============================================================================
# Build the CMEM kernel module for the configured platform, and make sure the
# kernel_binaries directory is kept in sync. Also, an explicit cleanup target
# is defined.
#==============================================================================
cmem:
	$(MAKE) -C $(LINUXUTILS_INSTALL_DIR)/packages/ti/sdo/linuxutils/cmem/src/interface ../../lib/cmem.a470MV RULES_MAKE=$(DVSDK_INSTALL_DIR)/Rules.make
	$(MAKE) -C $(LINUXUTILS_INSTALL_DIR)/packages/ti/sdo/linuxutils/cmem/src/module RULES_MAKE=$(DVSDK_INSTALL_DIR)/Rules.make
ifeq ($(OVERRIDE_KERNBIN),true)
	@mkdir -p $(DVSDK_INSTALL_DIR)/kernel_binaries/$(PLATFORM)
	@cp $(LINUXUTILS_INSTALL_DIR)/packages/ti/sdo/linuxutils/cmem/src/module/cmemk.ko $(DVSDK_INSTALL_DIR)/kernel_binaries/$(PLATFORM)/
	@echo
	@echo "cmemk.ko kernel module can be found under $(DVSDK_INSTALL_DIR)/kernel_binaries/$(PLATFORM)"
endif

cmem_clean:
	$(MAKE) -C $(LINUXUTILS_INSTALL_DIR)/packages/ti/sdo/linuxutils/cmem/src/module clean RULES_MAKE=$(DVSDK_INSTALL_DIR)/Rules.make
	$(MAKE) -C $(LINUXUTILS_INSTALL_DIR)/packages/ti/sdo/linuxutils/cmem/src/interface clean RULES_MAKE=$(DVSDK_INSTALL_DIR)/Rules.make

#==============================================================================
# Build SDMA for the configured platform. Also, an explicit cleanup
# target is defined.
#==============================================================================
sdma:
ifeq ($(HAS_SDMA),true)
	$(MAKE) -C $(LINUXUTILS_INSTALL_DIR)/packages/ti/sdo/linuxutils/sdma/src/module RULES_MAKE=$(DVSDK_INSTALL_DIR)/Rules.make
endif

sdma_clean:
ifeq ($(HAS_SDMA),true)
	$(MAKE) -C $(LINUXUTILS_INSTALL_DIR)/packages/ti/sdo/linuxutils/sdma/src/module clean RULES_MAKE=$(DVSDK_INSTALL_DIR)/Rules.make
endif
#==============================================================================

#==============================================================================
# Build the *production* codec servers for the configured platform. Also, an
# explicit cleanup target is defined.
# Please note the following.
#     1. Before executing make codecs, execute make codecs_clean
#     2. Build DSPLINK for arm and dsp before building the codecs
#     3. Buld the Linux kernel before building the dsplink
#==============================================================================
codecs:
ifeq ($(HAS_SERVER),true)
	$(MAKE) -C $(CODEC_INSTALL_DIR) DVSDK_INSTALL_DIR=$(DVSDK_INSTALL_DIR) BIOS_INSTALL_DIR=$(BIOS_INSTALL_DIR) XDC_INSTALL_DIR=$(XDC_INSTALL_DIR) CE_INSTALL_DIR=$(CE_INSTALL_DIR) FC_INSTALL_DIR=$(FC_INSTALL_DIR) CMEM_INSTALL_DIR=$(LINUXUTILS_INSTALL_DIR) CODEC_INSTALL_DIR=$(CODEC_INSTALL_DIR) BIOSUTILS_INSTALL_DIR=$(BIOSUTILS_INSTALL_DIR) XDAIS_INSTALL_DIR=$(XDAIS_INSTALL_DIR) EDMA3_LLD_INSTALL_DIR=$(EDMA3_LLD_INSTALL_DIR) CODEGEN_INSTALL_DIR=$(CODEGEN_INSTALL_DIR) LINK_INSTALL_DIR=$(LINK_INSTALL_DIR) XDCARGS=\"prod\"
endif

codecs_clean:
ifeq ($(HAS_SERVER),true)
	$(MAKE) -C $(CODEC_INSTALL_DIR) DVSDK_INSTALL_DIR=$(DVSDK_INSTALL_DIR) BIOS_INSTALL_DIR=$(BIOS_INSTALL_DIR) XDC_INSTALL_DIR=$(XDC_INSTALL_DIR) CE_INSTALL_DIR=$(CE_INSTALL_DIR) FC_INSTALL_DIR=$(FC_INSTALL_DIR) CMEM_INSTALL_DIR=$(LINUXUTILS_INSTALL_DIR) CODEC_INSTALL_DIR=$(CODEC_INSTALL_DIR) BIOSUTILS_INSTALL_DIR=$(BIOSUTILS_INSTALL_DIR) XDAIS_INSTALL_DIR=$(XDAIS_INSTALL_DIR) LINK_INSTALL_DIR=$(LINK_INSTALL_DIR) XDCARGS=\"prod\" clean
endif

#==============================================================================
# Build the dmammapk kernel module (if the configured for the platform). Also,
# an explicit cleanup target is defined.
#==============================================================================
dmammapk:
ifneq ($(DMAMMAP_INSTALL_DIR),)
	$(MAKE) -C $(DMAMMAP_INSTALL_DIR) KERNEL_DIR=$(LINUXKERNEL_INSTALL_DIR)
	@mkdir -p $(DVSDK_INSTALL_DIR)/kernel_binaries/$(PLATFORM)
	@cp $(DMAMMAP_INSTALL_DIR)/*.ko $(DVSDK_INSTALL_DIR)/kernel_binaries/$(PLATFORM)/
	@echo
	@echo "dmammapk kernel module can be found under $(DVSDK_INSTALL_DIR)/kernel_binaries/$(PLATFORM)"
endif

dmammapk_clean:
ifneq ($(DMAMMAP_INSTALL_DIR),)
	$(MAKE) -C $(DMAMMAP_INSTALL_DIR) KERNEL_DIR=$(LINUXKERNEL_INSTALL_DIR) clean
endif

#==============================================================================
# Build the edma kernel module (if the configured platform is dm365). Also,
# an explicit cleanup target is defined.
#==============================================================================
edmak:
ifeq ($(HAS_EDMAK),true)
	$(MAKE) -C $(LINUXUTILS_INSTALL_DIR)/packages/ti/sdo/linuxutils/edma/src/module KERNEL_DIR=$(LINUXKERNEL_INSTALL_DIR)
	@mkdir -p $(DVSDK_INSTALL_DIR)/kernel_binaries/$(PLATFORM)
	@cp $(LINUXUTILS_INSTALL_DIR)/packages/ti/sdo/linuxutils/edma/src/module/edmak.ko $(DVSDK_INSTALL_DIR)/kernel_binaries/$(PLATFORM)/
	@echo
	@echo "edmak.ko kernel module can be found under $(DVSDK_INSTALL_DIR)/kernel_binaries/$(PLATFORM)"
endif

edmak_clean:
ifeq ($(HAS_EDMAK),true)
	$(MAKE) -C $(LINUXUTILS_INSTALL_DIR)/packages/ti/sdo/linuxutils/edma/src/module KERNEL_DIR=$(LINUXKERNEL_INSTALL_DIR) clean
endif

#==============================================================================
# Build the irq kernel module (if the configured platform is dm365). Also,
# an explicit cleanup target is defined.
#==============================================================================
irqk:
ifeq ($(HAS_IRQK),true)
	$(MAKE) -C $(LINUXUTILS_INSTALL_DIR)/packages/ti/sdo/linuxutils/irq/src/module KERNEL_DIR=$(LINUXKERNEL_INSTALL_DIR)
	@mkdir -p $(DVSDK_INSTALL_DIR)/kernel_binaries/$(PLATFORM)
	@cp $(LINUXUTILS_INSTALL_DIR)/packages/ti/sdo/linuxutils/irq/src/module/irqk.ko $(DVSDK_INSTALL_DIR)/kernel_binaries/$(PLATFORM)/
	@echo
	@echo "irqk.ko kernel module can be found under $(DVSDK_INSTALL_DIR)/kernel_binaries/$(PLATFORM)"
endif

irqk_clean:
ifeq ($(HAS_IRQK),true)
	$(MAKE) -C $(LINUXUTILS_INSTALL_DIR)/packages/ti/sdo/linuxutils/irq/src/module KERNEL_DIR=$(LINUXKERNEL_INSTALL_DIR) clean
endif

#==============================================================================
#==============================================================================
# Build the DVSDK examples for the configured platform. Also, an explicit
# cleanup target is defined.
#==============================================================================
#examples:
#	$(MAKE) -C examples/$(PLATFORM)

#examples_clean:
#	$(MAKE) -C examples/$(PLATFORM) clean

#==============================================================================
# Build the Davinci Multimedia Application Interface for the configured
# platform. Also, an explicit cleanup target is defined.
#==============================================================================
dmai:
	@$(MAKE) -C $(DMAI_INSTALL_DIR) PLATFORM=${DMAI_PLATFORM} \
			CE_INSTALL_DIR_${DMAI_PLATFORM}=$(CE_INSTALL_DIR) \
				CODEC_INSTALL_DIR_${DMAI_PLATFORM}=$(CODEC_INSTALL_DIR) \
				LINK_INSTALL_DIR_${DMAI_PLATFORM}=$(LINK_INSTALL_DIR) \
				CMEM_INSTALL_DIR_${DMAI_PLATFORM}=$(CMEM_INSTALL_DIR) \
				FC_INSTALL_DIR_${DMAI_PLATFORM}=$(FC_INSTALL_DIR) \
				LPM_INSTALL_DIR_${DMAI_PLATFORM}=$(LPM_INSTALL_DIR) \
				XDAIS_INSTALL_DIR_${DMAI_PLATFORM}=$(XDAIS_INSTALL_DIR) \
				BIOS_INSTALL_DIR_${DMAI_PLATFORM}=$(BIOS_INSTALL_DIR) \
				LINUXLIBS_INSTALL_DIR_${DMAI_PLATFORM}=$(LINUXLIBS_INSTALL_DIR)\
				LINUXKERNEL_INSTALL_DIR_${DMAI_PLATFORM}=$(LINUXKERNEL_INSTALL_DIR) \
				CROSS_COMPILE_${DMAI_PLATFORM}=$(CSTOOL_PREFIX) \
				XDC_INSTALL_DIR_${DMAI_PLATFORM}=$(XDC_INSTALL_DIR) \
				EXEC_DIR_${DMAI_PLATFORM}=$(EXEC_DIR) all

	@echo
	@echo "DMAI applications can be found under $(DMAI_INSTALL_DIR)/packages/ti/sdo/dmai/apps"
	@echo "To install them to $(EXEC_DIR)"
	@echo "Execute 'make dmai_install'"

dmai_clean:
	$(MAKE) -C $(DMAI_INSTALL_DIR) PLATFORM=${DMAI_PLATFORM} \
		XDC_INSTALL_DIR_${DMAI_PLATFORM}=$(XDC_INSTALL_DIR) clean

dmai_install:
	$(MAKE) -C $(DMAI_INSTALL_DIR) PLATFORM=${DMAI_PLATFORM} EXEC_DIR=$(EXEC_DIR) install

#==============================================================================
# Build DSP Link for the configured platform. Also, an explicit cleanup target
# is defined.
#==============================================================================
ifeq ($(HAS_DSPLINK),true)
dsplink:	dsplink_arm dsplink_dsp dsplink_samples

dsplink_dsp_genpackage:
	$(XDC_INSTALL_DIR)/xdc -C $(LINK_INSTALL_DIR)/packages/dsplink/dsp clean 
	$(XDC_INSTALL_DIR)/xdc -C $(LINK_INSTALL_DIR)/packages/dsplink/dsp .interfaces

dsplink_gpp_genpackage:
	$(XDC_INSTALL_DIR)/xdc -C $(LINK_INSTALL_DIR)/packages/dsplink/gpp clean 
	$(XDC_INSTALL_DIR)/xdc -C $(LINK_INSTALL_DIR)/packages/dsplink/gpp .interfaces
	
dsplink_cfg:
	DSPLINK=$(LINK_INSTALL_DIR)/packages/dsplink perl $(LINK_INSTALL_DIR)/packages/dsplink/config/bin/dsplinkcfg.pl $(DSPLINK_CONFIG)

dsplink_arm:	dsplink_cfg dsplink_gpp_genpackage
	DSPLINK=$(LINK_INSTALL_DIR)/packages/dsplink $(XDC_INSTALL_DIR)/gmake -C $(LINK_INSTALL_DIR)/packages/dsplink/gpp/src BASE_TOOLCHAIN=$(MVTOOL_DIR) BASE_BUILDOS=$(LINUXKERNEL_INSTALL_DIR) KERNEL_DIR=${LINUXKERNEL_INSTALL_DIR} TOOL_PATH=$(CSTOOL_DIR)/bin debug
	DSPLINK=$(LINK_INSTALL_DIR)/packages/dsplink $(XDC_INSTALL_DIR)/gmake -C $(LINK_INSTALL_DIR)/packages/dsplink/gpp/src BASE_TOOLCHAIN=$(MVTOOL_DIR) BASE_BUILDOS=$(LINUXKERNEL_INSTALL_DIR) KERNEL_DIR=${LINUXKERNEL_INSTALL_DIR} TOOL_PATH=$(CSTOOL_DIR)/bin release
ifeq ($(OVERRIDE_KERNBIN),true)
	@mkdir -p $(DVSDK_INSTALL_DIR)/kernel_binaries/$(PLATFORM)
	@cp $(DSPLINK_MODULE) $(DVSDK_INSTALL_DIR)/kernel_binaries/$(PLATFORM)/
	@echo
	@echo "dsplinkk.ko kernel module can be found under $(DVSDK_INSTALL_DIR)/kernel_binaries/$(PLATFORM)"
endif

dsplink_dsp:	dsplink_cfg dsplink_dsp_genpackage
	DSPLINK=$(LINK_INSTALL_DIR)/packages/dsplink $(XDC_INSTALL_DIR)/gmake -C $(LINK_INSTALL_DIR)/packages/dsplink/dsp/src BASE_SABIOS=$(BIOS_INSTALL_DIR) XDCTOOLS_DIR=$(XDC_INSTALL_DIR) BASE_CGTOOLS=$(CODEGEN_INSTALL_DIR) debug
	DSPLINK=$(LINK_INSTALL_DIR)/packages/dsplink $(XDC_INSTALL_DIR)/gmake -C $(LINK_INSTALL_DIR)/packages/dsplink/dsp/src BASE_SABIOS=$(BIOS_INSTALL_DIR) XDCTOOLS_DIR=$(XDC_INSTALL_DIR) BASE_CGTOOLS=$(CODEGEN_INSTALL_DIR) release

dsplink_samples:
	DSPLINK=$(LINK_INSTALL_DIR)/packages/dsplink $(XDC_INSTALL_DIR)/gmake -C $(LINK_INSTALL_DIR)/packages/dsplink/gpp/src/samples BASE_TOOLCHAIN=$(MVTOOL_DIR) BASE_BUILDOS=$(LINUXKERNEL_INSTALL_DIR)
	DSPLINK=$(LINK_INSTALL_DIR)/packages/dsplink $(XDC_INSTALL_DIR)/gmake -C $(LINK_INSTALL_DIR)/packages/dsplink/dsp/src/samples BASE_SABIOS=$(BIOS_INSTALL_DIR) XDCTOOLS_DIR=$(XDC_INSTALL_DIR) BASE_CGTOOLS=$(CODEGEN_INSTALL_DIR)
else
dsplink:
endif

ifeq ($(HAS_DSPLINK),true)
dsplink_clean:
	DSPLINK=$(LINK_INSTALL_DIR)/packages/dsplink $(XDC_INSTALL_DIR)/gmake -C $(LINK_INSTALL_DIR)/packages/dsplink/gpp/src BASE_TOOLCHAIN=$(MVTOOL_DIR) BASE_BUILDOS=$(LINUXKERNEL_INSTALL_DIR) clean
	DSPLINK=$(LINK_INSTALL_DIR)/packages/dsplink $(XDC_INSTALL_DIR)/gmake -C $(LINK_INSTALL_DIR)/packages/dsplink/dsp/src BASE_SABIOS=$(BIOS_INSTALL_DIR) XDCTOOLS_DIR=$(XDC_INSTALL_DIR) BASE_CGTOOLS=$(CODEGEN_INSTALL_DIR) clean
	DSPLINK=$(LINK_INSTALL_DIR)/packages/dsplink $(XDC_INSTALL_DIR)/gmake -C $(LINK_INSTALL_DIR)/packages/dsplink/gpp/src/samples BASE_TOOLCHAIN=$(MVTOOL_DIR) BASE_BUILDOS=$(LINUXKERNEL_INSTALL_DIR) clean
	DSPLINK=$(LINK_INSTALL_DIR)/packages/dsplink $(XDC_INSTALL_DIR)/gmake -C $(LINK_INSTALL_DIR)/packages/dsplink/dsp/src/samples BASE_SABIOS=$(BIOS_INSTALL_DIR) XDCTOOLS_DIR=$(XDC_INSTALL_DIR) BASE_CGTOOLS=$(CODEGEN_INSTALL_DIR) clean
else
dsplink_clean:
endif

#==============================================================================
# Install the built binaries to the target file system.
#==============================================================================
install:
	@echo
	@echo Creating $(EXEC_DIR)
	@mkdir -p $(EXEC_DIR)

ifneq ($(PLATFORM),omap3530)
	@echo Copying kernel modules to target file system: $(EXEC_DIR)/
	@install -m 666 $(DVSDK_INSTALL_DIR)/kernel_binaries/$(PLATFORM)/* $(EXEC_DIR)/
endif

	@echo Installing DVSDK demos..
	$(MAKE) -C $(DEMO_INSTALL_DIR)/$(PLATFORM) install EXEC_DIR=$(EXEC_DIR)

ifneq ($(PLATFORM),omap3530)
#	@echo Copying examples..
#	@cp -rp examples/$(PLATFORM)/web $(EXEC_DIR)/
	@cp -p examples/$(PLATFORM)/dvevmdemo $(EXEC_DIR)/
endif

ifeq ($(PLATFORM),omap3530)
	@echo Installing clips..
	$(MAKE) -C clips install
endif

ifeq ($(PLATFORM),dm6446)
	@echo Copying codec servers..
	@install -m 666 $(CODEC_INSTALL_DIR)/packages/ti/sdo/servers/encode/encodeCombo.x64P $(EXEC_DIR)/
	-@install -m 666 $(CODEC_INSTALL_DIR)/packages/ti/sdo/servers/encode/encodeCombo_e.x64P $(EXEC_DIR)/
	@install -m 666 $(CODEC_INSTALL_DIR)/packages/ti/sdo/servers/decode/decodeCombo.x64P $(EXEC_DIR)/
	-@install -m 666 $(CODEC_INSTALL_DIR)/packages/ti/sdo/servers/decode/decodeCombo_e.x64P $(EXEC_DIR)/
	@install -m 666 $(CODEC_INSTALL_DIR)/packages/ti/sdo/servers/loopback/loopbackCombo.x64P $(EXEC_DIR)/
	-@install -m 666 $(CODEC_INSTALL_DIR)/packages/ti/sdo/servers/loopback/loopbackCombo_e.x64P $(EXEC_DIR)/
	@echo Copying dsplinkk.ko
	@install -m 666 $(LINK_INSTALL_DIR)/dsplink/gpp/export/BIN/Linux/DAVINCI/RELEASE/dsplinkk.ko $(EXEC_DIR)/
endif

ifeq ($(PLATFORM),dm6467)
	@echo Copying codec servers..
	@install -m 666 $(CODEC_INSTALL_DIR)/packages/ti/sdo/server/cs/bin/cs.x64P $(EXEC_DIR)/
	@echo Copying mapdmaqhd..
	@install -m 777 $(DVSDK_INSTALL_DIR)/mapdmaq-hd/mapdmaq-hd $(EXEC_DIR)/
endif

ifeq ($(PLATFORM),dm355)
	@echo Copying mapdmaq..
	@install -m 777 $(DVSDK_INSTALL_DIR)/mapdmaq/mapdmaq $(EXEC_DIR)/
endif

ifeq ($(PLATFORM),omap3530)
	@echo
	@echo Copying kernel modules to target file system: $(EXEC_DIR)/
	@echo Copying cmemk.ko
	@install -m 755 $(CMEM_INSTALL_DIR)/packages/ti/sdo/linuxutils/cmem/src/module/cmemk.ko $(EXEC_DIR)/
	@echo Copying dsplinkk.ko
	@install -m 755 $(LINK_INSTALL_DIR)/packages/dsplink/gpp/export/BIN/Linux/OMAP3530/RELEASE/dsplinkk.ko $(EXEC_DIR)/
	@echo Copying lpm_omap3530.ko
	@install -m 755 $(LPM_INSTALL_DIR)/packages/ti/bios/power/modules/omap3530/lpm/lpm_omap3530.ko $(EXEC_DIR)/
	@echo Copying sdmak.ko
	@install -m 755 $(CMEM_INSTALL_DIR)/packages/ti/sdo/linuxutils/sdma/src/module/sdmak.ko $(EXEC_DIR)/
	@echo Copying codec servers from $(CODEC_INSTALL_DIR)
	@install -m 755 $(CODEC_INSTALL_DIR)/packages/ti/sdo/server/cs/bin/cs.x64P $(EXEC_DIR)/
	@chmod -x $(EXEC_DIR)/*.x64P $(EXEC_DIR)/*.ko
endif
