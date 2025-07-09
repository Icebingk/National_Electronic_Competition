library verilog;
use verilog.vl_types.all;
entity fft256_tb is
    generic(
        NUM_FRAMES_c    : integer := 4;
        MAXVAL_c        : integer := 32768;
        OFFSET_c        : integer := 65536;
        MAXVAL_EXP_c    : integer := 32;
        OFFSET_EXP_c    : integer := 64
    );
end fft256_tb;
