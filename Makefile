# Makefile to use with Icarus Verilog and GTKWave

# Tools
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Source files
SOURCES = uart_rx.v uart_tx.v uart_tb.v

# Output files
VVP_FILE = uart_test.vvp
WAVE_FILE = uart_test.vcd

# Default target
all: $(VVP_FILE)

# Compile the design
$(VVP_FILE): $(SOURCES)
	$(IVERILOG) -o $(VVP_FILE) $(SOURCES)

# Run the simulation
run: $(VVP_FILE)
	$(VVP) $(VVP_FILE)

# View waveforms
wave: $(WAVE_FILE)
	$(GTKWAVE) $(WAVE_FILE)

# Clean up generated files
clean:
	rm -f $(VVP_FILE) $(WAVE_FILE)

.PHONY: all run wave clean