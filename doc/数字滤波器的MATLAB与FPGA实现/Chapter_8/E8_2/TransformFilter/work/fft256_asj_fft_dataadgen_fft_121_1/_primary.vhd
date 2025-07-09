library verilog;
use verilog.vl_types.all;
entity fft256_asj_fft_dataadgen_fft_121_1 is
    port(
        global_clock_enable: in     vl_logic;
        rd_addr_a_0     : out    vl_logic;
        rd_addr_a_1     : out    vl_logic;
        rd_addr_a_2     : out    vl_logic;
        rd_addr_a_3     : out    vl_logic;
        rd_addr_a_4     : out    vl_logic;
        rd_addr_a_5     : out    vl_logic;
        rd_addr_a_6     : out    vl_logic;
        rd_addr_a_7     : out    vl_logic;
        p_2             : in     vl_logic;
        p_0             : in     vl_logic;
        p_1             : in     vl_logic;
        rd_addr_a_01    : out    vl_logic;
        k_count_2       : in     vl_logic;
        k_count_0       : in     vl_logic;
        k_count_6       : in     vl_logic;
        k_count_3       : in     vl_logic;
        k_count_1       : in     vl_logic;
        k_count_7       : in     vl_logic;
        k_count_4       : in     vl_logic;
        k_count_5       : in     vl_logic;
        clk             : in     vl_logic
    );
end fft256_asj_fft_dataadgen_fft_121_1;
