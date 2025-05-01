library verilog;
use verilog.vl_types.all;
entity fft256_altsyncram_1 is
    port(
        q_b             : out    vl_logic_vector(31 downto 0);
        clocken0        : in     vl_logic;
        wren_a          : in     vl_logic;
        data_a          : in     vl_logic_vector(31 downto 0);
        address_a       : in     vl_logic_vector(7 downto 0);
        address_b       : in     vl_logic_vector(7 downto 0);
        clock0          : in     vl_logic
    );
end fft256_altsyncram_1;
