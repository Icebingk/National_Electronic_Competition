library verilog;
use verilog.vl_types.all;
entity fft256_asj_fft_twadsogen_q_fft_121 is
    port(
        twad_tempo_0    : out    vl_logic;
        twad_tempe_1    : out    vl_logic;
        twad_tempe_2    : out    vl_logic;
        twad_tempe_3    : out    vl_logic;
        twad_tempe_4    : out    vl_logic;
        twad_tempe_5    : out    vl_logic;
        twad_tempo_1    : out    vl_logic;
        twad_tempo_2    : out    vl_logic;
        twad_tempo_3    : out    vl_logic;
        twad_tempo_4    : out    vl_logic;
        twad_tempo_5    : out    vl_logic;
        k_count_tw_0    : in     vl_logic;
        k_count_tw_2    : in     vl_logic;
        k_count_tw_1    : in     vl_logic;
        k_count_tw_3    : in     vl_logic;
        k_count_tw_5    : in     vl_logic;
        k_count_tw_4    : in     vl_logic;
        k_count_tw_7    : in     vl_logic;
        k_count_tw_6    : in     vl_logic;
        global_clock_enable: in     vl_logic;
        quad_reg_2      : out    vl_logic;
        quad_reg_0      : out    vl_logic;
        quad_reg_1      : out    vl_logic;
        p_tdl_0_10      : in     vl_logic;
        p_tdl_1_10      : in     vl_logic;
        p_tdl_2_10      : in     vl_logic;
        data_addr_held_by1: out    vl_logic;
        data_addr_held_by2: out    vl_logic;
        clk             : in     vl_logic
    );
end fft256_asj_fft_twadsogen_q_fft_121;
