library verilog;
use verilog.vl_types.all;
entity fft256_scfifo_udh1 is
    port(
        q               : out    vl_logic_vector(33 downto 0);
        dffe_af1        : out    vl_logic;
        empty_dff       : out    vl_logic;
        rdreq           : in     vl_logic;
        sink_staterun1  : in     vl_logic;
        sink_stateend1  : in     vl_logic;
        wrreq           : in     vl_logic;
        counter_reg_bit_0: out    vl_logic;
        data            : in     vl_logic_vector(33 downto 0);
        fifo_wrreq      : in     vl_logic;
        clock           : in     vl_logic;
        reset_n         : in     vl_logic
    );
end fft256_scfifo_udh1;
