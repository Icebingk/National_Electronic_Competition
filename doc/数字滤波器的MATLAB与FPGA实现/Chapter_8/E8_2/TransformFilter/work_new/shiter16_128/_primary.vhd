library verilog;
use verilog.vl_types.all;
entity shiter16_128 is
    port(
        clock           : in     vl_logic;
        shiftin         : in     vl_logic_vector(15 downto 0);
        shiftout        : out    vl_logic_vector(15 downto 0);
        taps            : out    vl_logic_vector(2047 downto 0)
    );
end shiter16_128;
