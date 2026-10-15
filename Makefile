#==============================================================================
# Systolic Array Matrix Multiplication — simulation Makefile
# Flow: simulate → VCD → optional GTKWave
# Requires: iverilog, vvp. Optional: gtkwave
#==============================================================================

IVERILOG ?= iverilog
VVP      ?= vvp
GTKWAVE  ?= gtkwave
FLAGS    ?= -g2012

RTL = rtl/mac_unit.v \
      rtl/pe.v \
      rtl/systolic_array.v \
      rtl/controller.v \
      rtl/input_buffers.v \
      rtl/output_regs.v \
      rtl/systolic_top.v \
      rtl/seq_matmul.v

.PHONY: all dirs pe systolic compare test \
        show_pe show_systolic show_compare clean

all: test

dirs:
	mkdir -p sim waveforms

pe: dirs
	$(IVERILOG) $(FLAGS) -o sim/tb_pe.out rtl/mac_unit.v rtl/pe.v tb/tb_pe.v
	$(VVP) sim/tb_pe.out
	@cp -f sim/tb_pe.vcd waveforms/ 2>/dev/null || true

systolic: dirs
	$(IVERILOG) $(FLAGS) -o sim/tb_systolic.out $(RTL) tb/tb_systolic.v
	$(VVP) sim/tb_systolic.out
	@cp -f sim/tb_systolic.vcd waveforms/ 2>/dev/null || true

compare: dirs
	$(IVERILOG) $(FLAGS) -o sim/tb_compare.out $(RTL) tb/tb_compare.v
	$(VVP) sim/tb_compare.out
	@cp -f sim/tb_compare.vcd waveforms/ 2>/dev/null || true

test: pe systolic compare
	@echo ""
	@echo "=== All simulation targets finished ==="
	@echo "VCDs: sim/ and waveforms/"

show_pe: pe
	$(GTKWAVE) waveforms/tb_pe.vcd &

show_systolic: systolic
	$(GTKWAVE) waveforms/tb_systolic.vcd &

show_compare: compare
	$(GTKWAVE) waveforms/tb_compare.vcd &

clean:
	rm -rf sim/*.out sim/*.vcd waveforms/*.vcd
