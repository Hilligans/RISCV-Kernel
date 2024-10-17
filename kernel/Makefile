TOOLCHAIN_PATH=/usr/local/riscvmulti/bin/
PREF=$(TOOLCHAIN_PATH)riscv64-unknown-elf-
CC=$(PREF)gcc
AS=$(PREF)as
LD=$(PREF)ld
CFLAGS = -Wall -std=c99 -pedantic -g

BUILD_DIR = build
LIB_DIR = lib
BIN_DIR = bin
SRC = src
COMPILER_FLAGS = -march=rv64g -mabi=lp64 -static -mcmodel=medany \
  -fvisibility=hidden -nostdlib -nostartfiles -Tsifive_u/hello.ld -Isifive_u


SOURCES := $(wildcard $(SRC)/*.c)
OBJECTS := $(patsubst $(SRC)/%.c, $(BUILD_DIR)/%.o, $(SOURCES))

EXECUTABLES = $(BIN_DIR)/kernel

.PHONY: all clean

all: $(EXECUTABLES)

clean:
	rm -rf build/ lib/ bin/ $(EXECUTABLES)

# directories

$(BUILD_DIR) $(LIB_DIR) $(BIN_DIR) :
	mkdir -p $@

# compiling object files

$(BUILD_DIR)/%.o : $(SRC)/%.c | $(BUILD_DIR)
	$(CC) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/%.o : $(SRC)/%.s | $(BUILD_DIR)
	$(AS) -c $(CFLAGS) $< -o $@

# linking

$(BIN_DIR)/kernel : $(OBJECTS) | $(BIN_DIR)
	$(CC) $(CFLAGS) $^ -o $@

# riscv64-unknown-elf-gcc -march=rv64g -mabi=lp64 -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Tsifive_u/hello.ld -Isifive_u hello.s -o hello
