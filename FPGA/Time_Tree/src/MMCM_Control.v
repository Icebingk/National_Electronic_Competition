module MMCM_Control(
    input wire      sys_clk,
    input wire      rst_n,

    output wire     clk_out1,

    output reg [7:0] frq,
    input  wire      frq_search_over,
    input  wire      clc_accompish,
    output wire      locked
);
localparam  IDLE        = 0,
            START       = 1,
            WRITE       = 2,
            WAIT        = 3,
            Once_OVER   = 4,
            OVER        = 5;

wire ready;
wire accomplish;

reg  [7:0] addra;
reg  [2:0] clk_choise;
wire [7:0] frq_mult_int_all;
wire [9:0] frq_mult_float_all;
wire [7:0] frq_div_int_all;
wire [7:0] frq_div_int;
wire [9:0] frq_div_float;

reg [2:0] cstate,nstate;
wire IDLE_START     = (cstate == IDLE) && (clc_accompish) && locked;
wire START_WRITE    = (cstate == START);
wire WRITE_WAIT     = (cstate == WRITE) && (clk_choise == 3'd1) && ready;
wire WAIT_Once_OVER = (cstate == WAIT) && locked;
wire Once_OVER_IDLE = (cstate == Once_OVER) && (addra != 8'd200);
wire Once_OVER_OVER = (cstate == Once_OVER) && (addra == 8'd200);
wire OVER_IDLE      = (cstate == OVER) && frq_search_over;

wire [7:0] frq_div_int_w = clk_choise ? frq_div_int : frq_div_int_all;
wire valid = cstate == WRITE;

// clk_choise ,0/1
always @(posedge sys_clk or negedge rst_n)begin
    if (!rst_n)begin
        clk_choise <= 3'd0;
    end else if (cstate == WRITE && ready)begin
        clk_choise <= 3'd1;
    end else if (cstate == Once_OVER_OVER)begin
        clk_choise <= 3'd0;
    end else begin
        clk_choise <= clk_choise;
    end
end

// addra 自增
always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)begin
        addra <= 8'd0;
        frq <= 8'd88;
    end else if (WAIT_Once_OVER) begin
        addra <= addra + 1'b1;
        frq <= frq + 1'b1;
    end else if (Once_OVER_OVER)begin
        addra <= 8'd0;
        frq <= 8'd88;
    end else begin
        addra <= addra;
        frq <= frq;
    end
end

// 状态机2
always @(*) begin
    case (cstate)
        IDLE: begin
            if (IDLE_START) begin
                nstate = START;
            end else begin
                nstate = IDLE;
            end
        end
        START: begin
            if (START_WRITE) begin
                nstate = WRITE;
            end else begin
                nstate = START;
            end
        end
        WRITE: begin
            if (WRITE_WAIT) begin
                nstate = WAIT;
            end else begin
                nstate = WRITE;
            end
        end
        WAIT: begin
            if (WAIT_Once_OVER) begin
                nstate = Once_OVER;
            end else begin
                nstate = WAIT;
            end
        end
        Once_OVER: begin
            if (Once_OVER_OVER) begin
                nstate = OVER;
            end else if (Once_OVER_IDLE)begin
                nstate = IDLE;
            end else begin
                nstate = Once_OVER;
            end
        end
        OVER: begin
            if (OVER_IDLE) begin
                nstate = IDLE;
            end else begin
                nstate = OVER;
            end
        end
        default: begin
            nstate = IDLE; // 默认状态 
        end
    endcase
end

// 状态机1
always @(posedge sys_clk or negedge rst_n)begin
    if (!rst_n)begin
        cstate <= IDLE;
    end else begin
        cstate <= nstate;
    end
end

frq_mult_int_rom frq_mult_int_rom_inst(
    .addra(addra),//8
    .clka(sys_clk),
    .douta(frq_mult_int_all)//8
    
);


frq_mult_float_rom frq_mult_float_rom_inst(
    .addra(addra),//8
    .clka(sys_clk),
    .douta(frq_mult_float_all)//10
    
);

frq_div_int_all_rom frq_div_int_all_rom_inst(
    .addra(addra),//8
    .clka(sys_clk),
    .douta(frq_div_int_all)//8
    
);

frq_div_int_rom frq_div_int_rom_inst(
    .addra(addra),//8
    .clka(sys_clk),
    .douta(frq_div_int)//8
    
);

frq_div_float_rom frq_div_float_rom_inst(
    .addra(addra),//8
    .clka(sys_clk),
    .douta(frq_div_float)//10
    
);

time_tree_dy  time_tree_dy_inst (
    .sys_clk(sys_clk),
    .rst_n(rst_n),

    .enable(1'b1),
    .valid(valid),
    .ready(ready),

    .clk_control_num(3'b1),
    .clk_choise(clk_choise),
    .phase_enable(1'b0), // 相位使能信号，暂时不使用
    .frq_mult_int(frq_mult_int_all),
    .frq_mult_float(frq_mult_float_all),
    .frq_div_int(frq_div_int_w),
    .frq_div_float(frq_div_float),
    .frq_phase_value(32'd0),
    .accomplish(accomplish),

    .error_sign(error_sign),
    .clk_out1(clk_out1),
    // .clk_dac(clk_dac),
    // .clk_fir(clk_fir),
    .locked(locked)
  );

endmodule