/////////////////////////////////////////////////////////
//
//  FIFO module
//
/////////////////////////////////////////////////////////

module fifo_top
# (parameter FIFO_DEPTH = 4,                            /* maximum number of fifo elements */
             DATA_WIDTH = 17,                           /* number of bits of each fifo element */
             ADDR_WIDTH = $clog2(FIFO_DEPTH)            /* number of bits needed to represent each fifo element */
  )
  (input  logic                  clk, rst_n,
   input  logic                  push_valid_in, pop_grant_in,
   output logic                  push_grant_out, pop_valid_out,
   input  logic [DATA_WIDTH-1:0] push_data_in,
   output logic [DATA_WIDTH-1:0] pop_data_out
  );
  
  logic [ADDR_WIDTH-1:0] rd_addr, wr_addr;              /* addresses of the fifo where to read/write data from/to */
  logic                  en;                            /* en is used to determine whether push_data_in is to be stored in the fifo */
  
  // fifo memory element
  fifo_mem #(.FIFO_DEPTH(FIFO_DEPTH),
             .DATA_WIDTH(DATA_WIDTH)
            ) fifo_mem_inst (
             .clk, .en,
             .rd_addr, .wr_addr,
             .push_data_in, .pop_data_out
            );
             
  // fifo control unit
  fifo_cu #(.FIFO_DEPTH(FIFO_DEPTH)
           ) fifo_cu_inst (
            .clk, .rst_n, 
            .push_valid_in, .pop_grant_in, 
            .push_grant_out, .pop_valid_out, 
            .rd_addr, .wr_addr
           );
            
  // en
  assign en = push_valid_in & push_grant_out;
endmodule: fifo_top
