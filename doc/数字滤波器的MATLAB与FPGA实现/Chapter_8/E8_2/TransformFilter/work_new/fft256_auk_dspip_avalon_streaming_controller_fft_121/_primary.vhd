library verilog;
use verilog.vl_types.all;
entity fft256_auk_dspip_avalon_streaming_controller_fft_121 is
    port(
        master_sink_ena : in     vl_logic;
        source_packet_error_0: out    vl_logic;
        source_packet_error_1: out    vl_logic;
        source_stall_reg1: out    vl_logic;
        sink_stall_reg1 : out    vl_logic;
        sink_ready_ctrl : out    vl_logic;
        sink_start      : in     vl_logic;
        empty_dff       : in     vl_logic;
        sink_stall      : in     vl_logic;
        packet_error_s_0: in     vl_logic;
        packet_error_s_1: in     vl_logic;
        stall_reg1      : out    vl_logic;
        Mux0            : in     vl_logic;
        clk             : in     vl_logic;
        reset_n         : in     vl_logic
    );
end fft256_auk_dspip_avalon_streaming_controller_fft_121;
