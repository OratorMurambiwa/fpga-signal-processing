vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xpm
vlib questa_lib/msim/xbip_utils_v3_0_16
vlib questa_lib/msim/axi_utils_v2_0_12
vlib questa_lib/msim/c_reg_fd_v12_0_12
vlib questa_lib/msim/xbip_dsp48_wrapper_v3_0_7
vlib questa_lib/msim/xbip_pipe_v3_0_12
vlib questa_lib/msim/c_addsub_v12_0_22
vlib questa_lib/msim/c_shift_ram_v12_0_21
vlib questa_lib/msim/mult_gen_v12_0_25
vlib questa_lib/msim/floating_point_v7_1_22
vlib questa_lib/msim/cmpy_v6_0_28
vlib questa_lib/msim/xfft_v9_1_16
vlib questa_lib/msim/xil_defaultlib

vmap xpm questa_lib/msim/xpm
vmap xbip_utils_v3_0_16 questa_lib/msim/xbip_utils_v3_0_16
vmap axi_utils_v2_0_12 questa_lib/msim/axi_utils_v2_0_12
vmap c_reg_fd_v12_0_12 questa_lib/msim/c_reg_fd_v12_0_12
vmap xbip_dsp48_wrapper_v3_0_7 questa_lib/msim/xbip_dsp48_wrapper_v3_0_7
vmap xbip_pipe_v3_0_12 questa_lib/msim/xbip_pipe_v3_0_12
vmap c_addsub_v12_0_22 questa_lib/msim/c_addsub_v12_0_22
vmap c_shift_ram_v12_0_21 questa_lib/msim/c_shift_ram_v12_0_21
vmap mult_gen_v12_0_25 questa_lib/msim/mult_gen_v12_0_25
vmap floating_point_v7_1_22 questa_lib/msim/floating_point_v7_1_22
vmap cmpy_v6_0_28 questa_lib/msim/cmpy_v6_0_28
vmap xfft_v9_1_16 questa_lib/msim/xfft_v9_1_16
vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xpm  -incr -mfcu  -sv "+incdir+../../../../../../../../../AMDDesignTools/2026.1/Vivado/data/rsb/busdef" \
"C:/AMDDesignTools/2026.1/Vivado/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm  -93  \
"C:/AMDDesignTools/2026.1/Vivado/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work xbip_utils_v3_0_16  -93  \
"../../../ipstatic/hdl/xbip_utils_v3_0_rfs.vhd" \

vcom -work axi_utils_v2_0_12  -93  \
"../../../ipstatic/hdl/axi_utils_v2_0_vh_rfs.vhd" \

vcom -work c_reg_fd_v12_0_12  -93  \
"../../../ipstatic/hdl/c_reg_fd_v12_0_vh_rfs.vhd" \

vcom -work xbip_dsp48_wrapper_v3_0_7  -93  \
"../../../ipstatic/hdl/xbip_dsp48_wrapper_v3_0_vh_rfs.vhd" \

vcom -work xbip_pipe_v3_0_12  -93  \
"../../../ipstatic/hdl/xbip_pipe_v3_0_rfs.vhd" \

vcom -work c_addsub_v12_0_22  -93  \
"../../../ipstatic/hdl/c_addsub_v12_0_rfs.vhd" \

vcom -work c_shift_ram_v12_0_21  -93  \
"../../../ipstatic/hdl/c_shift_ram_v12_0_rfs.vhd" \

vcom -work mult_gen_v12_0_25  -93  \
"../../../ipstatic/hdl/mult_gen_v12_0_rfs.vhd" \

vcom -work floating_point_v7_1_22  -93  \
"../../../ipstatic/hdl/floating_point_v7_1_vh_rfs.vhd" \

vcom -work cmpy_v6_0_28  -93  \
"../../../ipstatic/hdl/cmpy_v6_0_vh_rfs.vhd" \

vcom -work xfft_v9_1_16  -2008  \
"../../../ipstatic/hdl/xfft_v9_1_vh08_rfs.vhd" \

vcom -work xfft_v9_1_16  -93  \
"../../../ipstatic/hdl/xfft_v9_1_vh_rfs.vhd" \

vcom -work xil_defaultlib  -93  \
"../../../../fpga_signal_processing.gen/sources_1/ip/FftCore/sim/FftCore.vhd" \


vlog -work xil_defaultlib \
"glbl.v"

