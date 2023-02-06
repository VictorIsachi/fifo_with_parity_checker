/////////////////////////////////////////////////////////
//
//  Parity Check module
//
/////////////////////////////////////////////////////////

module parity_check
# (parameter PARITY     = 1'b1,                         /* indicates the parity of the checker: 1'b1 for EVEN, 1'b0 for ODD */
             P_BIT      = 1'b1,                         /* indicates the position of the parity bit: 1'b1 for LSB, 1'b0 for MSB; note that it is not used in my design */
             DATA_WIDTH = 17                            /* number of bits of each fifo element */
  )
  (input  logic                  pop_valid_out, grant_in,
   output logic                  pop_grant_in, valid_out,
   input  logic [DATA_WIDTH-1:0] data_out
  );
  
  logic data_odd;                                       /* indicates the oddness of data_out: 1 if data_out contains an odd number of 1's, 0 if data_out contains an even number of 1's */
  
  // compute the oddness of data_out
  assign data_odd = ^data_out;                          /* note that the oddness is given by the XOR of all the bits of data_out */
  
  // generate the appropriate logic for valid_out based of PARITY
  generate
    if (PARITY == 1'b1)                                 /* EVEN PARITY */
      assign valid_out = ~data_odd & pop_valid_out;     /* data_out is valid if it contains an even number of 1's and pop_valid_out is 1 */
    else                                                /* ODD PARITY */
      assign valid_out = data_odd & pop_valid_out;      /* data_out is valid if it contains an odd number of 1's and pop_valid_out is 1 */
  endgenerate
  
  // transmit readiness to pop data
  assign pop_grant_in = grant_in;
endmodule: parity_check
