bootrom_img=bootrom.img

GCC=riscv64-unknown-elf-gcc
OBJCOPY=riscv64-unknown-elf-objcopy


all: $(bootrom_img)
	@echo "IMAGE BUILD"

%.img: %.bin
	dd if=$< of=$@ bs=2048 count=1
	@echo "BIN BUILD"

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.elf: %.S linker.ld
	$(GCC) -Tlinker.ld $< -nostdlib -static -Wl,--no-gc-sections -o $@

run:

	sudo qemu-system-riscv64 \
	 -m 2G \
	  -smp 4 \
	  -bios bootrom.img \
	  -nographic \
	  -machine virt \
	  -device virtio-rng-pci 
clean:
	rm *.img
