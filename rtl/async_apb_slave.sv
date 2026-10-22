module async_apb_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic                  pclk, 
    input  logic                  presetn, 
    input  logic                  psel, 
    input  logic                  penable, 
    input  logic                  pwrite,
    input  logic [ADDR_WIDTH-1:0] paddr,
    input  logic [DATA_WIDTH-1:0] pwdata,
    
    output logic                  pready, 
    output logic                  pslverr,
    output logic [DATA_WIDTH-1:0] prdata
);

    logic [DATA_WIDTH-1:0] sys_ctrl;
    logic [DATA_WIDTH-1:0] sys_status;
    logic [DATA_WIDTH-1:0] data_in;
    logic [DATA_WIDTH-1:0] data_out;

    assign pready = 1'b1;
    assign sys_status = 32'hCAFE_BABE;
    assign data_out   = (sys_ctrl[0]) ? ~data_in : data_in;

    wire apb_access = psel & penable & pready;

    always_ff @(posedge pclk or negedge presetn) begin
        if (~presetn) begin 
            sys_ctrl <= 32'h0000_0000;
            data_in  <= 32'h0000_0000;
        end else if (apb_access && pwrite) begin
            case(paddr[7:0])
                8'h00: sys_ctrl <= pwdata;
                8'h08: data_in  <= pwdata;
                default: ;
            endcase
        end
    end

    always_comb begin 
        prdata  = 32'h0000_0000;
        pslverr = 1'b0;
        
        if (apb_access) begin
            if (pwrite) begin
                if (paddr[7:0] != 8'h00 && paddr[7:0] != 8'h08) begin
                    pslverr = 1'b1;
                end
            end
            else begin
                case(paddr[7:0])
                    8'h00: prdata = sys_ctrl;
                    8'h04: prdata = sys_status;
                    8'h08: prdata = data_in;
                    8'h0C: prdata = data_out;
                    default: begin
                        prdata  = 32'h0000_0000;
                        pslverr = 1'b1;
                    end
                endcase
            end
        end
    end

endmodule