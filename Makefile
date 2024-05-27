bootrom_img=bootrom.img

GCC=riscv64-unknown-elf-gcc
OBJCOPY=riscv64-unknown-elf-objcopy


all: $(bootrom_img)
	@echo "IMAGE BUILD"

%.img: %.bin
	dd if=$< of=$@ bs=1024 count=1
	@echo "BIN BUILD"

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.elf: %.S bootrom.lds
	$(GCC) -Tbootrom.lds $< -nostdlib -static -Wl,--no-gc-sections -o $@

run:
	../../Virtual\ Machines/_-scripts/qemu_risv.sh
clean:
	rm *.img

