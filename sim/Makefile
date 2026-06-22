# ==============================================================================
# AMBA AHB Multi-Slave Verification Environment Makefile
# Tool: Cadence Xcelium (xrun)
# ==============================================================================

# 1. Define Variables
SIM_TOOL   = xrun
FLAGS      = -64bit -sysv -timescale 1ns/1ps +access+rwc -coverage all -covoverwrite

# 2. List source files in strict compilation/elaboration order
RTL_SRCS   = ahb_pkg.sv \
             ahb_if.sv \
             tb_pkg.sv \
             ahb_master_burst.sv \
             ahb_interconnect.sv \
             ahb_slave_fast.sv \
             ahb_slave_slow.sv \
             ahb_system_top.sv

TB_SRCS    = tb_top.sv

ALL_SRCS   = $(RTL_SRCS) $(TB_SRCS)

# 3. Default Target: Run simulation in Command Line mode
all: run

# 4. Run Target (Batch / Non-GUI mode)
run: clean
	$(SIM_TOOL) $(FLAGS) $(ALL_SRCS) -run -l xrun_batch.log

# 5. GUI Target (Launches SimVision Interactive Waveform Window)
gui: clean
	$(SIM_TOOL) $(FLAGS) $(ALL_SRCS) -gui -run -l xrun_gui.log 

# 6. Clean Target: Flushes all compilation assets, database directories, and log fragments
clean:
	@rm -rf xcelium.d xrun.history xrun.log xrun_batch.log xrun_gui.log waves.shm
	@rm -f  .simvision_*.pcf waves.shm.log
	@echo "[CLEAN] Removed all previous compilation artifacts and waveform databases."

.PHONY: all run gui clean




