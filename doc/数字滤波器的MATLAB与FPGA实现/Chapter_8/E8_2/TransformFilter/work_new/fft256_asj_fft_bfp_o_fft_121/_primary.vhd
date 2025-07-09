library verilog;
use verilog.vl_types.all;
entity fft256_asj_fft_bfp_o_fft_121 is
    port(
        pipeline_dffe_27: in     vl_logic;
        pipeline_dffe_28: in     vl_logic;
        pipeline_dffe_29: in     vl_logic;
        pipeline_dffe_30: in     vl_logic;
        pipeline_dffe_31: in     vl_logic;
        source_valid_ctrl_sop: in     vl_logic;
        stall_reg       : in     vl_logic;
        source_stall_int_d: in     vl_logic;
        global_clock_enable: in     vl_logic;
        slb_i_0         : out    vl_logic;
        Mux2            : out    vl_logic;
        lut_out_0       : out    vl_logic;
        tdl_arr_0       : in     vl_logic;
        Mux1            : out    vl_logic;
        lut_out_1       : out    vl_logic;
        lut_out_2       : out    vl_logic;
        lut_out_21      : out    vl_logic;
        real_out_11     : in     vl_logic;
        real_out_12     : in     vl_logic;
        real_out_13     : in     vl_logic;
        real_out_14     : in     vl_logic;
        real_out_15     : in     vl_logic;
        tdl_arr_01      : in     vl_logic;
        clk             : in     vl_logic;
        reset_n         : in     vl_logic
    );
end fft256_asj_fft_bfp_o_fft_121;
