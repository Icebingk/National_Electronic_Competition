library verilog;
use verilog.vl_types.all;
entity fft256_altsyncram_he72 is
    port(
        q_a             : out    vl_logic_vector(15 downto 0);
        q_b             : out    vl_logic_vector(15 downto 0);
        address_a       : in     vl_logic_vector(5 downto 0);
        address_b       : in     vl_logic_vector(5 downto 0);
        clocken0        : in     vl_logic;
        data_a          : in     vl_logic_vector(15 downto 0);
        data_b          : in     vl_logic_vector(15 downto 0);
        clock0          : in     vl_logic
    );
end fft256_altsyncram_he72;
