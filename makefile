
HEADER += ./minivm/vm/gc.h
HEADER += ./minivm/vm/nanbox.h
HEADER += ./minivm/vm/lib.h
HEADER += ./minivm/vm/asm.h
HEADER += ./minivm/vm/opcode.h
HEADER += ./minivm/vm/ir/be/int3.h
HEADER += ./minivm/vm/ir/const.h
HEADER += ./minivm/vm/ir/toir.h
HEADER += ./minivm/vm/ir/ir.h
HEADER += ./minivm/vm/ir/build.h
HEADER += ./minivm/vm/config.h
HEADER += ./minivm/vm/bc.h

VMSRCS += ./minivm/vm/asm.c
VMSRCS += ./minivm/vm/ir/be/int3.c
VMSRCS += ./minivm/vm/ir/toir.c
VMSRCS += ./minivm/vm/ir/const.c
VMSRCS += ./minivm/vm/ir/build.c
VMSRCS += ./minivm/vm/ir/info.c
VMSRCS += ./minivm/vm/gc.c

SRCS := $(VMSRCS) $(JSSRC)

vmjs: $(SRCS) $(HEADER)
	$(CC) $(OPT) $(SRCS) -o vmjs -lm $(CFLAGS) $(LDFLAGS)
