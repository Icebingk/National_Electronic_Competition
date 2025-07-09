library verilog;
use verilog.vl_types.all;
entity fft256_asj_fft_m_k_counter_fft_121 is
    port(
        rdy_for_next_block: in     vl_logic;
        send_sop_s      : in     vl_logic;
        global_clock_enable: in     vl_logic;
        blk_done1       : out    vl_logic;
        counter_i       : in     vl_logic;
        p_2             : out    vl_logic;
        p_0             : out    vl_logic;
        p_1             : out    vl_logic;
        rd_addr_a_0     : in     vl_logic;
        k_count_2       : out    vl_logic;
        k_count_0       : out    vl_logic;
        k_count_6       : out    vl_logic;
        k_count_3       : out    vl_logic;
        k_count_1       : out    vl_logic;
        k_count_7       : out    vl_logic;
        k_count_4       : out    vl_logic;
        k_count_5       : out    vl_logic;
        data_rdy_vec_4  : in     vl_logic;
        next_pass_i1    : out    vl_logic;
        clk             : in     vl_logic;
        reset_n         : in     vl_logic
    );
end fft256_asj_fft_m_k_counter_fft_121;
