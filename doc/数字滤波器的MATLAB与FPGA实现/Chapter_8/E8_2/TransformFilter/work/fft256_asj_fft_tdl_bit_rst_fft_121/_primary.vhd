library verilog;
use verilog.vl_types.all;
entity fft256_asj_fft_tdl_bit_rst_fft_121 is
    port(
        global_clock_enable: in     vl_logic;
        tdl_arr_12      : out    vl_logic;
        tdl_arr_9       : in     vl_logic;
        clk             : in     vl_logic;
        reset_n         : in     vl_logic
    );
end fft256_asj_fft_tdl_bit_rst_fft_121;
