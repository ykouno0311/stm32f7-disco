# Makefile for STM32F7-Discovery-Blinky (fixed)

PROJECT = blinky

################
# Sources

SOURCES_S = Drivers/CMSIS/Device/ST/STM32F7xx/Source/Templates/gcc/startup_stm32f746xx.s

SOURCES_C = src/main.c
SOURCES_C += sys/stubs.c sys/_sbrk.c sys/_io.c
SOURCES_C += Drivers/CMSIS/Device/ST/STM32F7xx/Source/Templates/system_stm32f7xx.c
SOURCES_C += Drivers/BSP/STM32746G-Discovery/stm32746g_discovery.c
SOURCES_C += Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_gpio.c

SOURCES_CPP =

SOURCES = $(SOURCES_S) $(SOURCES_C) $(SOURCES_CPP)
OBJS = $(SOURCES_S:.s=.o) $(SOURCES_C:.c=.o) $(SOURCES_CPP:.cpp=.o)

################
# Includes and Defines

INCLUDES += -I . -I src -I sys
INCLUDES += -I Drivers/CMSIS/Include
INCLUDES += -I Drivers/CMSIS/Device/ST/STM32F7xx/Include
INCLUDES += -I Drivers/STM32F7xx_HAL_Driver/Inc
INCLUDES += -I Drivers/BSP/STM32746G-Discovery

DEFINES = -DSTM32 -DSTM32F7 -DSTM32F746xx -DSTM32F746NGHx -DSTM32F746G_DISCO

################
# Toolchain

PREFIX ?= arm-none-eabi
CC = $(PREFIX)-gcc
AS = $(CC)            # as の代わりに gcc を使う
LD = $(PREFIX)-gcc

MCUFLAGS = -mcpu=cortex-m7 -mlittle-endian -mthumb -mfloat-abi=hard -mfpu=fpv5-sp-d16
DEBUGFLAGS = -O0 -g -gdwarf-2

CFLAGS = -std=c11 -Wall -Wextra $(DEFINES) $(MCUFLAGS) $(DEBUGFLAGS) $(CFLAGS_EXTRA) $(INCLUDES)
ASFLAGS = $(MCUFLAGS)   # アセンブル用は最小限のターゲットフラグのみ

LDFLAGS = -static $(MCUFLAGS) -specs=nosys.specs \
         -Wl,--start-group -lgcc -lm -lc -lg -lstdc++ -lsupc++ -Wl,--end-group \
         -Wl,--gc-sections -T stm32f7-discovery.ld -L. -Lldscripts -Wl,-Map=$(PROJECT).map

# 明示ルール：.s を gcc でアセンブル
%.o: %.s
	@echo "AS $<"
	$(CC) $(ASFLAGS) -c $< -o $@

%.o: %.c
	@echo "CC $<"
	$(CC) $(CFLAGS) -c $< -o $@

CC = $(PREFIX)-gcc
AS = $(CC)
AR = $(PREFIX)-ar
LD = $(PREFIX)-gcc
NM = $(PREFIX)-nm
OBJCOPY = $(PREFIX)-objcopy
OBJDUMP = $(PREFIX)-objdump
READELF = $(PREFIX)-readelf
SIZE = $(PREFIX)-size
GDB = $(PREFIX)-gdb
RM = rm -f

################
# Flags

MCUFLAGS = -mcpu=cortex-m7 -mlittle-endian
MCUFLAGS += -mfloat-abi=hard -mfpu=fpv5-sp-d16
MCUFLAGS += -mthumb

DEBUGFLAGS = -O0 -g -gdwarf-2
#DEBUGFLAGS = -O2

CFLAGS = -std=c11
CFLAGS += -Wall -Wextra --pedantic

# 分離しておく（リンカオプションは LDFLAGS に）
CFLAGS_EXTRA = -nostartfiles -fdata-sections -ffunction-sections

# 統一して適用
CFLAGS += $(DEFINES) $(MCUFLAGS) $(DEBUGFLAGS) $(CFLAGS_EXTRA) $(INCLUDES)
ASFLAGS = $(MCUFLAGS) $(DEBUGFLAGS)
LDFLAGS = -static $(MCUFLAGS) -specs=nosys.specs
LDFLAGS += -Wl,--start-group -lgcc -lm -lc -lg -lstdc++ -lsupc++ -Wl,--end-group
LDFLAGS += -Wl,--gc-sections
LDFLAGS += -T stm32f7-discovery.ld -L. -Lldscripts
LDFLAGS += -Wl,-Map=$(PROJECT).map

################
# Build rules

all: $(PROJECT).hex

$(PROJECT).hex: $(PROJECT).elf
	$(OBJCOPY) -O ihex $(PROJECT).elf $(PROJECT).hex

$(PROJECT).elf: $(OBJS)
	$(LD) $(OBJS) $(LDFLAGS) -o $(PROJECT).elf
	$(SIZE) -A $(PROJECT).elf

clean:
	$(RM) $(OBJS) $(PROJECT).elf $(PROJECT).hex $(PROJECT).map

# EOF