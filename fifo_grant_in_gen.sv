/////////////////////////////////////////////////////////
//
//  FIFO grant_in generator
//
/////////////////////////////////////////////////////////

module fifo_grant_in_gen 
  (fifo_if.GRANT_IN_GEN fifo_if_inst, 
   input fifo_tb_pkg::grant_in_e grant_in_ctrl          /* used to communicate with the module resposible for trafic generation */
  );

  import fifo_tb_pkg::*;
  
  // sets grant_in based on the desired bandwidth
  // NOTE: the simulator I used did not allow randcase
  //       a better implementation of: 
  //       if ($urandom_range(0,1) > 0)
  //         fifo_if_inst.grant_in <= 1'b0;
  //       else
  //         fifo_if_inst.grant_in <= 1'b1;
  //       would be:
  //       randcase
  //         1: fifo_if_inst.grant_in <= 1'b0;
  //         1: fifo_if_inst.grant_in <= 1'b1;
  //       endcase
  always @ (posedge fifo_if_inst.clk, grant_in_ctrl) begin
    unique case (grant_in_ctrl)
      BW_000: fifo_if_inst.grant_in <= 1'b0;            /* fill fifo */
      BW_050: begin                                     /* random trafic at 50% BW */
        if ($urandom_range(0,1) > 0)                    /* true with probability 1/2 */
          fifo_if_inst.grant_in <= 1'b0;
        else
          fifo_if_inst.grant_in <= 1'b1;
      end
      BW_100: fifo_if_inst.grant_in <= 1'b1;            /* empty fifo */
    endcase
  end
endmodule: fifo_grant_in_gen