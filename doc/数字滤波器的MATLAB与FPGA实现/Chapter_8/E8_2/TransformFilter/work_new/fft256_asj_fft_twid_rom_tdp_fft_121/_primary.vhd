library verilog;
use verilog.vl_types.all;
entity fft256_asj_fft_twid_rom_tdp_fft_121 is
    port(
        q_a             : out    vl_logic_vector(15 downto 0);
        q_b             : out    vl_logic_vector(15 downto 0);
        address_a       : in     vl_logic_vector(5 downto 0);
        address_b       : in     vl_logic_vector(5 downto 0);
        global_clock_enable: in     vl_logic;
        GND_port        : in     vl_logic;
        clock           : in     vl_logic
    );
end fft256_asj_fft_twid_rom_tdp_fft_121;
