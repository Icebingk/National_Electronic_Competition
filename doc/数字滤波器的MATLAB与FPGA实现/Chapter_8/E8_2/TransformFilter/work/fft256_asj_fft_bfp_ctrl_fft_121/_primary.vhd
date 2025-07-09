library verilog;
use verilog.vl_types.all;
entity fft256_asj_fft_bfp_ctrl_fft_121 is
    port(
        rdy_for_next_block: in     vl_logic;
        global_clock_enable: in     vl_logic;
        blk_exp_0       : out    vl_logic;
        blk_exp_1       : out    vl_logic;
        blk_exp_2       : out    vl_logic;
        blk_exp_3       : out    vl_logic;
        blk_exp_4       : out    vl_logic;
        blk_exp_5       : out    vl_logic;
        sop_d           : in     vl_logic;
        slb_i_0         : in     vl_logic;
        Mux2            : in     vl_logic;
        lut_out_0       : in     vl_logic;
        tdl_arr_0       : out    vl_logic;
        Mux1            : in     vl_logic;
        lut_out_1       : in     vl_logic;
        lut_out_2       : in     vl_logic;
        lut_out_21      : in     vl_logic;
        tdl_arr_9       : in     vl_logic;
        slb_last_1      : out    vl_logic;
        slb_last_0      : out    vl_logic;
        slb_last_2      : out    vl_logic;
        GND_port        : in     vl_logic;
        clk             : in     vl_logic;
        reset_n         : in     vl_logic
    );
end fft256_asj_fft_bfp_ctrl_fft_121;
