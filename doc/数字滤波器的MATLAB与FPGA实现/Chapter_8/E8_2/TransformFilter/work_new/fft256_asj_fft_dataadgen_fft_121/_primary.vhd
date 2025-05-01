library verilog;
use verilog.vl_types.all;
entity fft256_asj_fft_dataadgen_fft_121 is
    port(
        k_count_wr_2    : in     vl_logic;
        k_count_wr_0    : in     vl_logic;
        k_count_wr_6    : in     vl_logic;
        k_count_wr_3    : in     vl_logic;
        k_count_wr_1    : in     vl_logic;
        k_count_wr_7    : in     vl_logic;
        k_count_wr_4    : in     vl_logic;
        k_count_wr_5    : in     vl_logic;
        global_clock_enable: in     vl_logic;
        rd_addr_a_0     : out    vl_logic;
        rd_addr_a_1     : out    vl_logic;
        rd_addr_a_2     : out    vl_logic;
        rd_addr_a_3     : out    vl_logic;
        rd_addr_a_4     : out    vl_logic;
        rd_addr_a_5     : out    vl_logic;
        rd_addr_a_6     : out    vl_logic;
        rd_addr_a_7     : out    vl_logic;
        p_tdl_0_18      : in     vl_logic;
        p_tdl_1_18      : in     vl_logic;
        p_tdl_2_18      : in     vl_logic;
        clk             : in     vl_logic
    );
end fft256_asj_fft_dataadgen_fft_121;
