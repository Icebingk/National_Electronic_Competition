library verilog;
use verilog.vl_types.all;
entity generic_pll is
    generic(
        lpm_type        : string  := "generic_pll";
        duty_cycle      : integer := 50;
        output_clock_frequency: string  := "0 ps";
        phase_shift     : string  := "0 ps";
        reference_clock_frequency: string  := "0 ps";
        sim_additional_refclk_cycles_to_lock: integer := 0
    );
    port(
        refclk          : in     vl_logic;
        rst             : in     vl_logic;
        fbclk           : in     vl_logic;
        outclk          : out    vl_logic;
        locked          : out    vl_logic;
        fboutclk        : out    vl_logic
    );
end generic_pll;
