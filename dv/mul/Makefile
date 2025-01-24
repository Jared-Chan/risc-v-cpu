ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
endif

INCLUDE_DIR := ../../rtl/

FILES := \
    ./mul_tb.sv

TOP := mul_tb

SUPPRESS_WARNING := -Wno-WIDTHTRUNC

default:
	@echo "-- VERILATE & BUILD --------"
	$(VERILATOR) --binary -j 0 $(FLAGS) $(SUPPRESS_WARNING) -y $(INCLUDE_DIR) $(FILES) --top-module $(TOP)
	@echo "-- RUN ---------------------"
	obj_dir/V$(TOP)
	@echo "-- DONE --------------------"



