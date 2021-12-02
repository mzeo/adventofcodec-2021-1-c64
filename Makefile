.PHONY: run clean map build

%.prg: %.asm
	kickass $< -o $@ -debugdump

build: disk.d64

run: main.prg
	bash -c "x64 -autostartprgmode 1 main.prg"

disk.d64: main.prg
	c1541 -format advent,12 d64 disk.d64
	c1541 -attach disk.d64 -write main.prg
	c1541 -attach disk.d64 -list

clean:
	-rm main.prg main.sym main.dbg disk.d64
