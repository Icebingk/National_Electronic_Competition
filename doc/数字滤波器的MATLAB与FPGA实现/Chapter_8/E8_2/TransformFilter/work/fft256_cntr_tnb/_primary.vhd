library verilog;
use verilog.vl_types.all;
entity fft256_cntr_tnb is
    port(
        counter_reg_bit_0: out    vl_logic;
        counter_reg_bit_1: out    vl_logic;
        \_\             : in     vl_logic;
        clock           : in     vl_logic;
        reset_n         : in     vl_logic
    );
end fft256_cntr_tnb;
