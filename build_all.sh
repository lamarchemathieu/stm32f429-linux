#!/bin/sh

rm -rf image.bin
truncate -s 2M image.bin

cd afboot-stm32
make clean
make KERNEL_ADDR=0x08008000 DTB_ADDR=0x08002000 stm32f429i-disco
cd ..

dd if=afboot-stm32/stm32f429i-disco.bin of=image.bin bs=1024 conv=notrunc

cd linux
make ARCH=arm CROSS_COMPILE=arm-none-eabi- mrproper
cp ../linux.config .config
make ARCH=arm CROSS_COMPILE=arm-none-eabi- -j`nproc`
cd ..

dd if=linux/arch/arm/boot/dts/stm32f429-disco.dtb of=image.bin seek=8 bs=1024 conv=notrunc
dd if=linux/arch/arm/boot/xipImage of=image.bin seek=32 bs=1024 conv=notrunc

openocd -f board/stm32f429discovery.cfg \
-c "init" \
-c "reset init" \
-c "flash probe 0" \
-c "flash info 0" \
-c "flash write_image erase image.bin 0x08000000" \
-c "reset run" \
-c "shutdown"
