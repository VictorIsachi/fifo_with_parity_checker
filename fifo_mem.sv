/////////////////////////////////////////////////////////
//
//  FIFO memory module
//
/////////////////////////////////////////////////////////

module fifo_mem
# (parameter FIFO_DEPTH = 4,                            /* maximum number of fifo elements */
             DATA_WIDTH = 17,                           /* number of bits of each fifo element */
             ADDR_WIDTH = $clog2(FIFO_DEPTH)            /* number of bits needed to represent each fifo element */
  )
  (input  logic                  clk, en,               /* en is used to determine whether push_data_in is to be stored in the fifo */
   input  logic [ADDR_WIDTH-1:0] rd_addr, wr_addr,      /* addresses of the fifo where to read/write data from/to */
   input  logic [DATA_WIDTH-1:0] push_data_in,
   output logic [DATA_WIDTH-1:0] pop_data_out
  );
  
  logic [DATA_WIDTH-1:0] fifo [FIFO_DEPTH];             /* fifo memory array, starts at index 0 */
  
  // fifo reading
  always @ (posedge clk)
    if (en) fifo[wr_addr] <= push_data_in;
    
  // fifo writing
  assign pop_data_out = fifo[rd_addr];
endmodule: fifo_mem