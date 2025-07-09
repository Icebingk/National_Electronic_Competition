library verilog;
use verilog.vl_types.all;
entity fft256_altsyncram_ssf1 is
    port(
        q_b             : out    vl_logic_vector(33 downto 0);
        clocken1        : in     vl_logic;
        wren_a          : in     vl_logic;
        data_a          : in     vl_logic_vector(33 downto 0);
        address_a       : in     vl_logic_vector(2 downto 0);
        address_b       : in     vl_logic_vector(2 downto 0);
        clock0          : in     vl_logic;
        clock1          : in     vl_logic
    );
end fft256_altsyncram_ssf1;
