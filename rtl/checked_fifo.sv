/////////////////////////////////////////////////////////
//
//  FIFO with parity check module
//
/////////////////////////////////////////////////////////

module checked_fifo
# (parameter FIFO_DEPTH = 4,                            /* maximum number of fifo elements */
             DATA_WIDTH = 17,                           /* number of bits of each fifo element */
             PARITY     = 1'b1,                         /* indicates the parity of the checker: 1'b1 for EVEN, 1'b0 for ODD */
             P_BIT      = 1'b1                          /* indicates the position of the parity bit: 1'b1 for LSB, 1'b0 for MSB; note that it is not used in my design */
  )
  (input  logic                  clk, rst_n,
   input  logic                  valid_in, grant_in,
   output logic                  grant_out, valid_out,
   input  logic [DATA_WIDTH-1:0] data_in,
   output logic [DATA_WIDTH-1:0] data_out
  );
  
  logic pop_valid_out, pop_grant_in;
  
  // fifo top module
  fifo_top #(.FIFO_DEPTH(FIFO_DEPTH),
             .DATA_WIDTH(DATA_WIDTH)
            ) fifo_top_inst (
             .clk, .rst_n,
             .push_valid_in(valid_in), .pop_grant_in,
             .push_grant_out(grant_out), .pop_valid_out,
             .push_data_in(data_in), .pop_data_out(data_out)
            );
  
  // parity check module
  parity_check #(.PARITY(PARITY),
                 .P_BIT(P_BIT),
                 .DATA_WIDTH(DATA_WIDTH)
                ) parity_check_inst (
                 .pop_valid_out, .grant_in,
                 .pop_grant_in, .valid_out,
                 .data_out
                );
endmodule: checked_fifo
