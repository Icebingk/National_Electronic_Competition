library verilog;
use verilog.vl_types.all;
entity TransformFilter_vlg_tst is
    generic(
        clk_period      : integer := 20;
        data_num        : integer := 4800
    );
end TransformFilter_vlg_tst;
