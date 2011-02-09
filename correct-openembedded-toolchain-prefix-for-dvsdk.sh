#!/bin/bash

cd ${OVEROTOP}/tmp/sysroots/i686-linux/usr/armv7a/bin
ls | cut -d'-' -f5-99 | while read COMP
do
  ln -s arm-angstrom-linux-gnueabi-${COMP} arm-none-linux-gnueabi-${COMP} 
done
