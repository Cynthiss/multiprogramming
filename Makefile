# ==============================================================
# Makefile — BeagleBone bare-metal multiprogramming
# Autor : Dev B
# Fase  : 1
# ==============================================================
#
# Targets:
#   make        → compila solo el OS (Fase 1)
#   make os     → compila solo el OS
#   make p1     → aviso: deshabilitado en Fase 1
#   make p2     → aviso: deshabilitado en Fase 1
#   make clean  → elimina carpeta build/
#   make verify → verifica símbolos del OS sin BeagleBone
# ==============================================================

# ---- Toolchain -----------------------------------------------
CC      = arm-none-eabi-gcc
LD      = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
NM      = arm-none-eabi-nm
SIZE    = arm-none-eabi-size

# ---- Flags ---------------------------------------------------
CFLAGS  = -mcpu=cortex-a8 -marm        \
          -mfloat-abi=soft             \
          -ffreestanding -nostdlib     \
          -fno-builtin                 \
          -fno-stack-protector         \
          -Wall -Wextra -O1 -g

# ---- Directorios ---------------------------------------------
OS_DIR  = OS
LIB_DIR = lib
BUILD   = build

# ---- Objetos del OS ------------------------------------------
OS_OBJS = $(BUILD)/root.o          \
          $(BUILD)/os.o            \
          $(BUILD)/os_main.o       \
          $(BUILD)/scheduler.o     \
          $(BUILD)/lib_stdio.o     \
          $(BUILD)/lib_string.o

# ---- Outputs --------------------------------------------------
OS_ELF  = $(BUILD)/os.elf
OS_BIN  = $(BUILD)/os.bin
OS_LST  = $(BUILD)/os.lst
OS_MAP  = $(BUILD)/os.map

# ==============================================================
.PHONY: all os p1 p2 clean verify

all: os
	@echo ""
	@echo "===== Build completo (Fase 1) ====="
	@$(SIZE) $(OS_ELF)

$(BUILD):
	mkdir -p $(BUILD)

# ==============================================================
# OS
# ==============================================================
os: $(OS_BIN)

$(OS_ELF): $(OS_OBJS) $(OS_DIR)/os.ld
	$(LD) -T $(OS_DIR)/os.ld -Map=$(OS_MAP) -o $@ $(OS_OBJS)

$(OS_BIN): $(OS_ELF)
	$(OBJCOPY) -O binary $< $@
	@echo "[OS] Listo: $@ ($$(wc -c < $@) bytes)"
	@$(OBJDUMP) -d $< > $(OS_LST) 2>/dev/null || true

$(BUILD)/root.o: $(OS_DIR)/root.s | $(BUILD)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/os.o: $(OS_DIR)/os.c $(OS_DIR)/os.h $(OS_DIR)/pcb.h | $(BUILD)
	$(CC) $(CFLAGS) -I$(OS_DIR) -I$(LIB_DIR) -c -o $@ $<

$(BUILD)/os_main.o: $(OS_DIR)/os_main.c $(OS_DIR)/os.h $(OS_DIR)/scheduler.h | $(BUILD)
	$(CC) $(CFLAGS) -I$(OS_DIR) -I$(LIB_DIR) -c -o $@ $<

$(BUILD)/scheduler.o: $(OS_DIR)/scheduler.c $(OS_DIR)/scheduler.h $(OS_DIR)/os.h | $(BUILD)
	$(CC) $(CFLAGS) -I$(OS_DIR) -I$(LIB_DIR) -c -o $@ $<

$(BUILD)/lib_stdio.o: $(LIB_DIR)/stdio.c $(LIB_DIR)/stdio.h $(OS_DIR)/os.h | $(BUILD)
	$(CC) $(CFLAGS) -I$(OS_DIR) -I$(LIB_DIR) -c -o $@ $<

$(BUILD)/lib_string.o: $(LIB_DIR)/string.c $(LIB_DIR)/string.h | $(BUILD)
	$(CC) $(CFLAGS) -I$(OS_DIR) -I$(LIB_DIR) -c -o $@ $<

# ==============================================================
# P1 / P2 deshabilitados en Fase 1
# ==============================================================
p1:
	@echo "P1 está deshabilitado en Fase 1."

p2:
	@echo "P2 está deshabilitado en Fase 1."

# ==============================================================
# Clean
# ==============================================================
clean:
	rm -rf $(BUILD)
	@echo "Build eliminado."

# ==============================================================
# Verify — sin necesidad de BeagleBone
# ==============================================================
verify: os
	@echo "--- Símbolos clave del OS ---"
	@$(NM) $(OS_ELF) | grep -E "scheduler_init|os_main|timer_irq_handler|saved_regs|saved_lr|saved_svc_sp" || true
	@echo "--- Tamaños ---"
	@$(SIZE) $(OS_ELF)