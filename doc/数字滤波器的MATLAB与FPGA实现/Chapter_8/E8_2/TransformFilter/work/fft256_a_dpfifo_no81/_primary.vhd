library verilog;
use verilog.vl_types.all;
entity fft256_a_dpfifo_no81 is
    port(
        q               : out    vl_logic_vector(33 downto 0);
        empty_dff1      : out    vl_logic;
        rreq            : in     vl_logic;
        sink_staterun1  : in     vl_logic;
        sink_stateend1  : in     vl_logic;
        wreq            : in     vl_logic;
        counter_reg_bit_1: out    vl_logic;
        counter_reg_bit_0: out    vl_logic;
        counter_reg_bit_2: out    vl_logic;
        data            : in     vl_logic_vector(33 downto 0);
        wreq1           : in     vl_logic;
        clock           : in     vl_logic;
        reset_n         : in     vl_logic
    );
end fft256_a_dpfifo_no81;
