/*==============================================
* Function Name  : decoder.v
* Description    : 3-8译码器，纯组合逻辑
* input port     : A(三位输入)，EN(使能端)
* output port    : Y(八位输出端)
* Author         : ADBD
//==============================================*/
module decoder(
    input   wire    [2:0]   A,      //输入端: S1 S2 S3
    input   wire            EN,     //使能端: S4
    output  reg     [7:0]   Y       //输出端: LD8 - LD1
    );

always @(*) begin
    if(!EN) begin
        case(A)
            3'b000: Y <= 8'b1111_1110;    
            3'b001: Y <= 8'b1111_1101;
            3'b010: Y <= 8'b1111_1011;
            3'b011: Y <= 8'b1111_0111;
            3'b100: Y <= 8'b1110_1111;
            3'b101: Y <= 8'b1101_1111;
            3'b110: Y <= 8'b1011_1111;
            3'b111: Y <= 8'b0111_1111;
        endcase
    end else begin
        Y <= 8'b1111_1111;
    end
end

endmodule
