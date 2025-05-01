module flash_contorl (
    input   wire            sys_clk             ,
    input   wire            rst_n               ,

    input   wire            read_id_req         ,//读设备ID申请
    output  wire[23:0]      flash_id            ,//flash设备ID输出，3*8bit
    output  wire            read_id_end         ,//读设备ID结束

    input   wire            read_req            ,//读数据申请
    input   wire[23:0]      read_addr           ,//读数据地址
    input   wire[9:0]       read_size           ,//读数据大小
    output  wire[7:0]       read_data           ,//读数据输出
    output  wire            read_ack            ,//读数据应答
    output  wire            read_end            ,//读数据结束

    input   wire            write_enable_req    ,//写允许申请
    output  wire            write_enable_end    ,//写允许结束

    input   wire            write_disable_req   ,//写禁止申请
    output  wire            write_disable_end   ,//写禁止结束

    input   wire            write_req           ,//写数据申请
    input   wire[23:0]      write_page          ,//写数据地址
    input   wire[8:0]       write_size          ,//写数据大小
    input   wire[7:0]       write_data          ,//写数据
    output  wire            write_ack           ,//写数据应答
    output  wire            write_end           ,//写数据结束
    
    input   wire            erase_sector_req    ,//扇区擦除申请
    input   wire[23:0]      erase_sector_addr   ,//扇区擦除地址
    output  wire            erase_sector_end    ,//扇区擦除结束

    input   wire            erase_bulk_req      ,//片擦除申请
    output  wire            erase_bulk_end      ,//片擦除结束

    output  wire            spi_clk             ,
    output  wire            spi_mosi            ,
    input   wire            spi_miso            ,
    output  wire            spi_csn
);

//flash command   
`define Write_Enable                    8'h06//写使能命令
`define Write_Disable                   8'h04//写失能命令
`define Read_Identification             8'h9F//读设备ID命令
`define Read_Status_Reg                 8'h05//读状态命令
`define Write_Status_Reg                8'h01//写状态命令
`define Read_Data_Bytes                 8'h03//读数据命令
`define Read_Data_At_Higher_Speed       8'h0B//高速读数据命令
`define Page_Program                    8'h02//页编程命令
`define Sector_Erase                    8'hD8//扇区擦除命令
`define Bulk_Erase                      8'hC7//片擦除命令 

`define Read_Identification_Bytes       4'd4//读设备ID的字节数
`define Sector_Erase_Bytes              4'd4//扇区擦除的字节数
`define Bulk_Erase_Bytes                4'd1//片擦除的字节数

//para define
localparam  Page_Size                   =   9'd256;//页大小
localparam  Write_Enable_Wait           =   'd10;//写使能等待时间
localparam  Write_Disable_Wait           =   'd10;//写使能等待时间
localparam  Read_Data_Bytes_Wait        =   'd10;//读数据等待时间
localparam  Sector_Erase_Wait           =   32'd35_000_000;//扇区擦除等待时间
localparam  Page_Program_Wait           =   32'd350_000;//页编程等待时间
localparam  Bulk_Erase_Wait             =   32'd650_000_000;//片擦除等待时间
//13 state
localparam  Flash_Idle                  =   13'b0_0000_0000_0001;//空闲状态
localparam  Flash_Write_Enable          =   13'b0_0000_0000_0010;//写允许状态
localparam  Flash_Write_Disable         =   13'b0_0000_0000_0100;//写禁止状态
localparam  Flash_Read_Identification   =   13'b0_0000_0000_1000;//读设备ID状态
localparam  Flash_Read_Status_Reg       =   13'b0_0000_0001_0000;//读状态寄存器状态
localparam  Flash_Write_Status_Reg      =   13'b0_0000_0010_0000;//写状态寄存器状态
localparam  Flash_Read_Data_Bytes       =   13'b0_0000_0100_0000;//读数据状态
localparam  Flash_Read_Data_At_hSpeed   =   13'b0_0000_1000_0000;//高速读数据状态
localparam  Flash_Page_Program          =   13'b0_0001_0000_0000;//页编程状态
localparam  Flash_Sector_Erase          =   13'b0_0010_0000_0000;//扇区擦除状态
localparam  Flash_Bulk_Erase            =   13'b0_0100_0000_0000;//片擦除状态
localparam  Flash_Wait                  =   13'b0_1000_0000_0000;//等待状态
localparam  Flash_End                   =   13'b1_0000_0000_0000;//结束状态

//reg define
reg     [12:0]      state , next_state      ;//状态寄存器
reg     [12:0]      state_ts                ;//需要等待的状态，记录

//line spi
reg                 spi_write_req           ;
reg     [7:0]       spi_write_data          ;
wire                spi_write_ack           ;

reg                 spi_read_req            ;
wire    [7:0]       spi_read_data           ;
wire                spi_read_ack            ;

reg                 spi_csn_reg             ;//片选信号

//
reg     [9:0]       spi_wr_byte_cnt         ;//spi读写字节计数
reg     [23:0]      flash_id_reg            ;//存放flash设备ID
reg     [32:0]      pp_erase_wait_cnt       ;//页编程/擦除等待时间

//wire define
assign      spi_csn             =   spi_csn_reg; //spi片选信号，空闲、结束、等待状态下为高电平，工作状态下为低电平
assign      flash_id            =   flash_id_reg;//flash设备ID输出
assign      read_id_end         =   ((spi_wr_byte_cnt == `Read_Identification_Bytes - 1'b1) && spi_read_ack == 1'b1) ? 1'b1 : 1'b0;//写了1个命令，读了3个字节的设备ID，表示完成，输出1
assign      read_data           =   spi_read_data;//读数据输出
assign      read_ack            =   ((state == Flash_Read_Data_Bytes) && (spi_wr_byte_cnt > 'd3) && spi_read_ack == 1'b1) ? 1'b1 : 1'b0;//写了4个命令，1指令+3地址，表示申请结束，输出1
assign      read_end            =   ((state == Flash_Read_Data_Bytes) &&(spi_wr_byte_cnt == read_size + 'd1 + 'd3 - 1'b1) && spi_read_ack == 1'b1) ? 1'b1 : 1'b0;//读了指定大小的数据，表示完成，次数等于读数据大小+地址+指令
assign      write_enable_end    =   ((state == Flash_Write_Enable) &&(spi_wr_byte_cnt == 'd0) && spi_write_ack == 1'b1) ? 1'b1 : 1'b0;//当写允许命令发送完成，表示写使能完成，输出1
assign      Write_disable_end   =   ((state == Flash_Write_Disable) &&(spi_wr_byte_cnt == 'd0) && spi_write_ack == 1'b1) ? 1'b1 : 1'b0;//当写禁止命令发送完成，表示写禁止完成，输出1
assign      write_ack           =   ((state == Flash_Page_Program) && (spi_wr_byte_cnt > 'd3) && spi_write_ack == 1'b1) ? 1'b1 : 1'b0;//表示写数据1命令+3地址输出完成，输出1
assign      write_end           =   ((state == Flash_Page_Program) && (spi_wr_byte_cnt == write_size + 'd1 + 'd3 - 1'b1) && spi_write_ack == 1'b1) ? 1'b1 : 1'b0;//表示写数据完成，输出1
assign      erase_sector_end    =   ((state == Flash_Sector_Erase) && (spi_wr_byte_cnt == `Sector_Erase_Bytes - 1'b1) && spi_write_ack == 1'b1 ) ? 1'b1 : 1'b0; //表示擦除的扇区完成，输出1
assign      erase_bulk_end      =   ((state == Flash_Bulk_Erase) && (spi_wr_byte_cnt == `Bulk_Erase_Bytes - 1'b1)   && spi_write_ack == 1'b1 ) ? 1'b1 : 1'b0; //表示擦除的片完成，输出1

//
always@(posedge sys_clk or negedge rst_n)begin
    if( rst_n == 1'b0)
        state <= Flash_Idle;
    else
        state <= next_state;
end

//
always@(*)  begin
    case (state)
        Flash_Idle: 
            if( read_id_req == 1'b1)//读设备ID申请，进入读设备ID状态
                next_state <= Flash_Read_Identification;
            else if( write_enable_req == 1'b1)//写允许发送申请，进入写使能命令状态
                next_state <= Flash_Write_Enable;
            else if( write_req == 1'b1 )//写数据申请，进入写数据状态
                next_state <= Flash_Page_Program;
            else if(write_disable_req == 1'b1)//写禁止命令状态
                next_state <= Flash_Write_Disable;
            else if( read_req == 1'b1 )//读数据申请，进入读数据状态
                next_state <= Flash_Read_Data_Bytes;
            else if( erase_sector_req == 1'b1)//擦除扇区申请，进入擦除扇区状态
                next_state <= Flash_Sector_Erase;
            else if( erase_bulk_req == 1'b1 )//擦除片申请，进入擦除片状态
                next_state <= Flash_Bulk_Erase;
            else
                next_state <= Flash_Idle; 

        Flash_Read_Identification:
            if( (spi_wr_byte_cnt == `Read_Identification_Bytes - 1'b1) && spi_read_ack == 1'b1)//读设备ID命令发送完成，并且获取到3个字节的设备ID，表示读取完成
                next_state <= Flash_End;
            else
                next_state <= Flash_Read_Identification;
        Flash_Write_Enable:
            if( spi_write_ack == 1'b1)
                next_state <= Flash_Wait;//写完一个写允许命令，进入等待状态
            else
                next_state <= Flash_Write_Enable;
        Flash_Page_Program:
            if( (spi_wr_byte_cnt == write_size + 'd1 + 'd3 - 1'b1) && spi_write_ack == 1'b1) //写完指定大小的数据，进入等待状态
                next_state <= Flash_Wait;
            else
                next_state <= Flash_Page_Program;
        Flash_Write_Disable:
            if( spi_write_ack == 1'b1)
                next_state <= Flash_Wait;//写完一个写禁止命令，进入等待状态
            else
                next_state <= Flash_Write_Disable;
        Flash_Read_Data_Bytes:
            if( (spi_wr_byte_cnt == read_size + 'd1 + 'd3 - 1'b1) && spi_read_ack == 1'b1)  //读完指定大小的数据，进入等待状态
                next_state <= Flash_Wait;
            else
                next_state <= Flash_Read_Data_Bytes;
        Flash_Sector_Erase:
            if( (spi_wr_byte_cnt == `Sector_Erase_Bytes - 1'b1) && spi_write_ack == 1'b1)//擦除扇区命令发送完成，进入等待状态
                next_state <= Flash_Wait;
            else
                next_state <= Flash_Sector_Erase;
        Flash_Bulk_Erase:
            if( (spi_wr_byte_cnt == `Bulk_Erase_Bytes - 1'b1) && spi_write_ack == 1'b1)//擦除片区命令发送完成，进入等待状态
                next_state <= Flash_Wait;
            else
                next_state <= Flash_Bulk_Erase;
        Flash_Wait:
            if( state_ts == Flash_Page_Program && pp_erase_wait_cnt == Page_Program_Wait)
                next_state <= Flash_End;
            else if(state_ts == Flash_Sector_Erase && pp_erase_wait_cnt == Sector_Erase_Wait)
                next_state <= Flash_End;
            else if(state_ts == Flash_Bulk_Erase && pp_erase_wait_cnt == Bulk_Erase_Wait)
                next_state <= Flash_End;
            else if(state_ts == Flash_Read_Data_Bytes && pp_erase_wait_cnt == Read_Data_Bytes_Wait)
                next_state <= Flash_End;
            else if(state_ts == Flash_Write_Enable && pp_erase_wait_cnt == Write_Enable_Wait)
                next_state <= Flash_End;
            else if(state_ts == Flash_Write_Disable && pp_erase_wait_cnt == Write_Disable_Wait)
                next_state <= Flash_End;
            else
                next_state <= Flash_Wait;
        Flash_End:
            next_state <= Flash_Idle;
        default:    next_state <= Flash_Idle;
    endcase
end

//记录需要等待的状态
always@(posedge sys_clk or negedge rst_n ) begin
    if( rst_n == 1'b0)
        state_ts <= Flash_Idle;
    else if( state == Flash_Idle )
        if( write_req == 1'b1 )
            state_ts <= Flash_Page_Program;
        else if( erase_sector_req == 1'b1)
            state_ts <= Flash_Sector_Erase;
        else if( erase_bulk_req == 1'b1 )
            state_ts <= Flash_Bulk_Erase;
        else if( read_req == 1'b1)
            state_ts <= Flash_Read_Data_Bytes;
        else if( write_enable_req == 1'b1)
            state_ts <= Flash_Write_Enable;
        else if( write_disable_req == 1'b1)
            state_ts <= Flash_Write_Disable;
        else
            state_ts <= Flash_Idle; 
    else
        state_ts <= state_ts;
end

//等待时间计数
always@(posedge sys_clk or negedge rst_n)begin
    if( rst_n == 1'b0)
        pp_erase_wait_cnt <= 'd0;
    else if(state == Flash_Wait)
        pp_erase_wait_cnt <= pp_erase_wait_cnt + 1'b1;
    else    
        pp_erase_wait_cnt <= 'd0;

end

//在工作状态下拉低片选，空闲、等待、结束状态下拉高片选
always@(posedge sys_clk or negedge rst_n )begin
    if( rst_n == 1'b0)
        spi_csn_reg <= 1'b1;
    else if( state == Flash_Idle || state == Flash_End || state == Flash_Wait)
        spi_csn_reg <= 1'b1;
    else
        spi_csn_reg <= 1'b0;
end

//记录读写的byte数
always@(posedge sys_clk or negedge rst_n)begin
    if( rst_n == 1'b0 )
        spi_wr_byte_cnt <= 'd0;
    else if( state != next_state)   
        spi_wr_byte_cnt <= 'd0;
    else if( spi_read_ack == 1'b1 || spi_write_ack == 1'b1)
        spi_wr_byte_cnt <= spi_wr_byte_cnt + 1'b1;
    else    
        spi_wr_byte_cnt <= spi_wr_byte_cnt;
end


//
always@(posedge sys_clk or negedge rst_n)begin
    if( rst_n == 1'b0 )
        spi_read_req <= 1'b0;
    else if( state == Flash_Read_Identification && spi_wr_byte_cnt > 'd0)//读设备的时候，先等写指令，再在后三个byte计数读指令
        if((spi_wr_byte_cnt == `Read_Identification_Bytes - 1'b1) && spi_read_ack == 1'b1)//读到3个字节的时候，设备ID读取完成
            spi_read_req <= 1'b0;
        else
            spi_read_req <= 1'b1;
    else if(state == Flash_Read_Data_Bytes && spi_wr_byte_cnt > 'd3)//当读申请的命令+地址发送完成，开始读数据
        if((spi_wr_byte_cnt == read_size + 'd1 + 'd3 - 1'b1) && spi_read_ack == 1'b1)//当数据读完，将对spi的读请求置0
            spi_read_req <= 1'b0;
        else
            spi_read_req <= 1'b1;
    else
        spi_read_req <= 1'b0;
end


//
always@(posedge sys_clk or negedge rst_n)begin
    if( rst_n == 1'b0)
        flash_id_reg <= 'd0;
    else if( state == Flash_Read_Identification && spi_wr_byte_cnt > 'd0)//在读设备ID的状态下，等待spi的单byte数据读取完成，读取3个byte会退出此状态
        if( spi_read_ack == 1'b1)
            flash_id_reg <= {flash_id_reg[15:0],spi_read_data};//单byte数据读取完成，存入flash_id_reg
        else
            flash_id_reg <= flash_id_reg;
    else
        flash_id_reg <= flash_id_reg;
end


//
always@(posedge sys_clk or negedge rst_n)begin
    if( rst_n == 1'b0 )
        spi_write_req <= 1'b0;
    else if( state == Flash_Write_Enable)//写允许状态下，写使能命令发送
        spi_write_req <= 1'b1;
    else if( state == Flash_Write_Disable)//写禁止状态下，写使能命令发送
        spi_write_req <= 1'b1;
    else if( state == Flash_Read_Identification && spi_wr_byte_cnt == 'd0)//在读设备ID的状态下，第一个byte计数，先写指令
        spi_write_req <= 1'b1;
    else if( state == Flash_Page_Program)//写数据状态下，写数据发送
        spi_write_req <= 1'b1;
    else if( state == Flash_Read_Data_Bytes && spi_wr_byte_cnt < 'd4)//读数据状态下，先写入命令和地址
        spi_write_req <= 1'b1;
    else if( state == Flash_Sector_Erase && spi_wr_byte_cnt < 'd4 )//擦除扇区状态下，先写入命令和地址
        spi_write_req <= 1'b1;
    else if( state == Flash_Bulk_Erase )//擦除片状态下，写入擦除片命令
        spi_write_req <= 1'b1;
    else
        spi_write_req <= 1'b0;
end

//控制写入的数据
always@(posedge sys_clk or negedge rst_n)begin
    if( rst_n == 1'b0 )
        spi_write_data <= 8'd0;
    else if( state == Flash_Write_Enable )//写允许命令状态下，写入0x06
        spi_write_data <= `Write_Enable;
    else if( state == Flash_Read_Identification && spi_wr_byte_cnt == 'd0)//写指令为0x9F
        spi_write_data <= `Read_Identification;    
    else if( state == Flash_Page_Program)//写数据状态下，写入数据
        case(spi_wr_byte_cnt)//写入一个命令和三个地址
        'd0:     spi_write_data <= `Page_Program;
        'd1:     spi_write_data <= write_page[23:16];
        'd2:     spi_write_data <= write_page[15:8];
        'd3:     spi_write_data <= write_page[7:0];    
        default: spi_write_data <= write_data;
        endcase
    else if( state == Flash_Write_Disable )//写允许命令状态下，写入0x04
        spi_write_data <= `Write_Disable;
    else if(state == Flash_Read_Data_Bytes)//如数据状态下，先一个命令+三个地址
        if( spi_wr_byte_cnt == 'd0)
            spi_write_data <= `Read_Data_Bytes;
        else if( spi_wr_byte_cnt == 'd1)
            spi_write_data <= read_addr[23:16];
        else if( spi_wr_byte_cnt == 'd2)
            spi_write_data <= read_addr[15:8];
        else
            spi_write_data <= read_addr[7:0];
    else if( state == Flash_Sector_Erase)//擦除扇区状态下，先一个命令+三个地址
        if( spi_wr_byte_cnt == 'd0)
            spi_write_data <= `Sector_Erase;
        else if( spi_wr_byte_cnt == 'd1)
            spi_write_data <= erase_sector_addr[23:16];
        else if( spi_wr_byte_cnt == 'd2)
            spi_write_data <= erase_sector_addr[15:8];
        else
            spi_write_data <= erase_sector_addr[7:0];
    else if( state == Flash_Bulk_Erase)//擦除片状态下，写入擦除片命令
        spi_write_data <= `Bulk_Erase;
    else
        spi_write_data <= 8'd0;
end

//spi module
spi_master_flash inst_spi_master_flash(

    .sys_clk    (sys_clk),
    .rst_n        (rst_n),

    .read_req   (spi_read_req),
    .read_data  (spi_read_data),
    .read_ack   (spi_read_ack),

    .write_req  (spi_write_req),
    .write_data (spi_write_data),
    .write_ack  (spi_write_ack),

    .spi_clk     (spi_clk), 
    .spi_mosi    (spi_mosi),
    .spi_miso    (spi_miso)

);

endmodule