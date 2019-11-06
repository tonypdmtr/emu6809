LOPTIONS=
#TOPTIONS=/la /n

all: mc6809e.exe

mc6809e.exe: mc6809e.obj
 @tlink $(LOPTIONS) mc6809e
 @upx --ultra-brute mc6809e

mc6809e.obj: mc6809e.asm loader.asm opcodes1.asm opcodes2.asm os9.asm
 @tasm $(TOPTIONS) mc6809e
