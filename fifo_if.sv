/////////////////////////////////////////////////////////
//
//  FIFO interface
//
/////////////////////////////////////////////////////////

interface fifo_if(input logic clk);
  parameter              DATA_WIDTH = 17;               /* number of bits of each fifo element */
  logic [DATA_WIDTH-1:0] data_in, data_out;
  logic                  valid_in, valid_out;
  logic                  grant_in, grant_out;
  logic                  rst_n;
  
  // interface view of the DUT
  modport DUT (input  data_in, valid_in, grant_in, rst_n,
               output data_out, valid_out, grant_out);
               
  // interface view of the trafic generator
  modport TRAFIC_GEN (input  grant_out, clk,
                      output data_in, valid_in);
                      
  // interface view of the grant_in generator
  modport GRANT_IN_GEN (input  clk,
                        output grant_in);
  
  // interface view of the checker
  modport CHECKER (input data_in, valid_in, grant_in, clk, rst_n,
                         data_out, valid_out, grant_out);
endinterface: fifo_if