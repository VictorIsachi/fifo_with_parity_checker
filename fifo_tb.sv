/////////////////////////////////////////////////////////
//
//  FIFO testbench
//
/////////////////////////////////////////////////////////

module fifo_tb;
  import fifo_tb_pkg::*;
  
  parameter FIFO_DEPTH = 4,                             /* maximum number of fifo elements */
            DATA_WIDTH = 17,                            /* number of bits of each fifo element */
            PARITY     = 1'b1,                          /* indicates the parity of the checker: 1'b1 for EVEN, 1'b0 for ODD */
            P_BIT      = 1'b1;                          /* indicates the position of the parity bit: 1'b1 for LSB, 1'b0 for MSB; note that it is not used in my design */
  bit clk;
  grant_in_e grant_in_ctrl;                             /* communication between trafic generator and grant_in generator */

  // clock
  always #50 clk = ~clk;
  
  // reset
  initial begin
    if_inst.rst_n = 0;
    #200;
    if_inst.rst_n = 1;
  end
  
  // interface
  fifo_if if_inst(clk);

  // DUT
  checked_fifo #(.FIFO_DEPTH(FIFO_DEPTH),
                 .DATA_WIDTH(DATA_WIDTH),
                 .PARITY(PARITY),  
                 .P_BIT(P_BIT)     
                 ) dut (
                 .clk(if_inst.clk), .rst_n(if_inst.DUT.rst_n),
                 .valid_in(if_inst.DUT.valid_in), .grant_in(if_inst.DUT.grant_in),
                 .grant_out(if_inst.DUT.grant_out), .valid_out(if_inst.DUT.valid_out),
                 .data_in(if_inst.DUT.data_in),
                 .data_out(if_inst.DUT.data_out)
                 );
                 
  // trafic generator
  fifo_trafic_gen #(.FIFO_DEPTH(FIFO_DEPTH)) trafic_gen (.fifo_if_inst(if_inst), .grant_in_ctrl(grant_in_ctrl));
  
  // grant_in generator
  fifo_grant_in_gen grant_in_gen (.fifo_if_inst(if_inst), .grant_in_ctrl(grant_in_ctrl));
  
  // checker
  fifo_checker #(.FIFO_DEPTH(FIFO_DEPTH),
                 .DATA_WIDTH(DATA_WIDTH),
                 .PARITY(PARITY),  
                 .P_BIT(P_BIT)     
                 ) checker_inst (
                 .fifo_if_inst(if_inst)
                 );
endmodule: fifo_tb