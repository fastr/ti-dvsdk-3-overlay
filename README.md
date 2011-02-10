**Note:** Each branch has a slightly different README, tailored for that branch. Please select the appropriate branch.

Goal
====

A quick, easy, hassle-free DVSDK setup.

This guide is adapted from this [blog post](http://fastr.github.com/articles/ti-dsplink-on-OpenEmbedded.html), which is more verbose.

If this guide doesn't answer your questions, read that as well.


Downloads
====

According to TI's [Getting Started Guide: OMAP35x DVEVM Software Setup](http://processors.wiki.ti.com/index.php/GSG:_OMAP35x_DVEVM_Software_Setup#Installing_the_DVSDK_Software_.28DVSDK_version_3.01.00.09_onwards.29), you'll need the following packages:

  * [dvsdk_3_01_00_10_Setup.bin][ti-dvsdk-3] - source for `cmem`, `dsplink`, `lpm`, `sdma`, etc
  * [TI-C6x-CGT-v6.1.12.bin][ti-cgt-6] - DSP compiler
  * [data_dvsdk_3_01_00_10.tar.gz (direct link)][ti-dvsdk-3-data] - example files to run demos on
  * [cs1omap3530_setupLinux_1_01_00-prebuilt-dvsdk3.01.00.10.bin][ti-codec-server-1]
  * [AM35x-OMAP35x-PSP-SDK-03.00.01.06.tgz][ti-am-psp-sdk-3] - root file system
    * Documentation found in `AM35x-OMAP35x-PSP-SDK-##.##.##.##/docs/omap3530/UserGuide-##.##.##.##.pdf`, once extracted.
    * This is similar to the OpenEmedded `omap3-console-image`, but for TI's EVM board.
  * [codesoucery_tools (direct link)][cst-arm2009q1-203] - compiler toolchain
    * This is TI's partner's version of OpenEmbedded's `gcc-cross` which contains `arm-none-gnueabi-gcc` and friends.

For compiling code which uses the DSP intrinsics you'll need `dsplib64plus`, `dsplib64plus.h`, `dsplib64plus.lib`

  * [C64x+ DSP Library (DSPLIB)][dsplib-web] ([direct link][dsplib-direct])
    * [How to include this library][e2e-dsplib-howto] in a project


Installation
====

I'll assume that you've downloaded the above to `~/Downloads` and that you accept the default paths

    DVSDKDIR=~/dvsdk

    cd ~/Downloads
    # Accept the defaults
    ./dvsdk_3_01_00_10_Setup.bin --mode console --prefix ${DVSDKDIR}
    ./cs1omap3530_setupLinux_1_01_00-prebuilt-dvsdk3.01.00.10.bin --mode console --prefix ${DVSDKDIR}/dvsdk_3_01_00_10
    sudo ./ti_cgt_c6000_6.1.12_setup_linux_x86.bin --mode console
    echo 'export C6000_C_DIR=/opt/TI/C6000CGT6.1.12/include:/opt/TI/C6000CGT6.1.12/lib' >> ~/.bashrc
    echo 'export C6X_C_DIR=${C6000_C_DIR}' >> ~/.bashrc
    source ~/.bashrc
    
Although `CSTOOL_PREFIX` should allow you to change your toolchain prefix, it's hard coded to `arm-none-linux-gnueabi` in some places.

If your compiler toolchain uses a different prefix you will need to link it to the name TI's tools expect.

Example (Overo on OpenEmbedded):

    cd ${OVEROTOP}/tmp/sysroots/i686-linux/usr/armv7a/bin
    ls | cut -d'-' -f5-99 | while read COMP
    do
      ln -s arm-angstrom-linux-gnueabi-${COMP} arm-none-linux-gnueabi-${COMP} 
    done


Configuration
====

`~/dvsdk/dvsdk_3_01_00_10/Rules.make`

    * `DVSDK_INSTALL_DIR=$(HOME)/dvsdk/dvsdk_3_01_00_10`
    * `CODEGEN_INSTALL_DIR=/opt/TI/C6000CGT6.1.12`
    * `OMAP3503_SDK_INSTALL_DIR=$(HOME)/AM35x-OMAP35x-PSP-SDK-03.00.01.06`
    * `CSTOOL_DIR=$(OVEROTOP)/tmp/sysroots/i686-linux/usr/armv7a`
    * `CSTOOL_PREFIX=$(CSTOOL_DIR)/bin/arm-angstrom-linux-gnueabi-`
    * `LINUXKERNEL_INSTALL_DIR=$(OVEROTOP)/tmp/work/overo-angstrom-linux-gnueabi/linux-omap3-2.6.36`

`~/dvsdk/dvsdk_3_01_00_10/Makefile`

    * `LINUXKERNEL_CONFIG=omap3_defconfig`
    * `UBOOT_CONFIG=omap3_overo_config`


Test
====

    bitbake x-load u-boot-omap3 linux-omap3-2.6.36

    cd ~/dvsdk/dvsdk_3_01_00_10
    make help
    make clobber # super clean
    make everything
    make linux cmem sdma lpm dsplink

[ti-dvsdk-3]: http://software-dl.ti.com/dsps/dsps_public_sw/sdo_sb/targetcontent/dvsdk/DVSDK_3_00/latest/index_FDS.html
[ti-cgt-6]: http://software-dl.ti.com/dsps/dsps_public_sw/sdo_sb/targetcontent/dvsdk/DVSDK_3_00/latest/index_FDS.html
[ti-dvsdk-3-data]: http://software-dl.ti.com/dsps/dsps_public_sw/sdo_sb/targetcontent/dvsdk/DVSDK_3_00/latest/exports/data_dvsdk_3_01_00_10.tar.gz
[ti-codec-server-1]: http://software-dl.ti.com/dsps/dsps_public_sw/sdo_sb/targetcontent/dvsdk/DVSDK_3_00/latest/index_FDS.html
[ti-am-psp-sdk-3]: http://software-dl.ti.com/dsps/dsps_public_sw/psp/LinuxPSP/OMAP_03_00/03_00_01_06/index_FDS.html
[cst-arm2009q1-203]: http://www.codesourcery.com/sgpp/lite/arm/portal/package4571/public/arm-none-linux-gnueabi/arm-2009q1-203-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2
[dsplib-web]: http://focus.ti.com/docs/toolsw/folders/print/sprc265.html
[dsplib-direct]: http://software-dl.ti.com/dsps/dsps_public_sw/c6000/web/c64p_dsplib/latest/exports//c64plus-dsplib_2_02_00_00_Linux-x86_Setup.bin
[e2e-dsplib-howto]: http://e2e.ti.com/support/embedded/f/354/p/60639/217114.aspx#217114
