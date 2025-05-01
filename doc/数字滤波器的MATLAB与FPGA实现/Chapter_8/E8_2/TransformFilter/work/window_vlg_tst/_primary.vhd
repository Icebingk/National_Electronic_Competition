library verilog;
use verilog.vl_types.all;
entity window_vlg_tst is
    generic(
        clk_period      : integer := 400;
        data_num        : integer := 2000
    );
end window_vlg_tst;
