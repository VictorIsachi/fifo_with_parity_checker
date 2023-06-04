/////////////////////////////////////////////////////////
//
//  FIFO trafic generator
//
/////////////////////////////////////////////////////////

module fifo_trafic_gen
# (parameter FIFO_DEPTH = 4,                            /* maximum number of fifo elements */
             DATA_WIDTH = 17                            /* number of bits of each fifo element */
  )
  (fifo_if.TRAFIC_GEN fifo_if_inst, 
   output fifo_tb_pkg::grant_in_e grant_in_ctrl         /* used to communicate with the module responsible grant_in */
  );
  
  import fifo_tb_pkg::*;
  
  ////////////////////                          ////////////////////
  ////////////  DEFINE THE BEHAVIOUR OF THE SIMULATION  ////////////
  ////////////////////                          ////////////////////
  initial begin
    fill_fifo();
    
    empty_fifo();
    
    fork                                                /* run 50% bandwith trafic for 5000 units of time */
      random_trafic(BW_050);
      #5000;
    join_any
    disable fork;
    fifo_if_inst.valid_in <= 1'b0;                      /* in case the thread is killed before it resets valid_in */
    
    fork                                                /* run 100% bandwith trafic for 5000 units of time */
      random_trafic(BW_100);
      #5000;
    join_any
    disable fork;
    fifo_if_inst.valid_in <= 1'b0;                      /* in case the thread is killed before it resets valid_in */
    
    empty_fifo();
    
    $stop;
  end
  
  // sends the stimulus to the DUT starting from the sequence item
  task send_seq_item(fifo_seq_item seq_item);
    wait (fifo_if_inst.grant_out == 1)                  /* wait for the fifo to grant push permission */
    
    for (int i = 0; i < DATA_WIDTH; i++)
      fifo_if_inst.data_in[i] <= seq_item.data[i];
    fifo_if_inst.valid_in <= 1'b1;
    
    @(posedge fifo_if_inst.clk);                        /* wait the beginning of the next clock cycle to reset the validity of the pushed data */
    fifo_if_inst.valid_in <= 1'b0;
  endtask: send_seq_item
  
  // generates random, continuous, DUT trafic
  task random_trafic(grant_in_e bw);
    fifo_seq_item seq_item;
    
    grant_in_ctrl = bw;
    
    forever begin
      seq_item = new();
      VALID_RANDOMIZATION: assert (randomize(seq_item))
      else $error("Sequence item randomization failed");
      send_seq_item(seq_item);
    end
  endtask: random_trafic
  
  // writes enough trafic to fill the DUT capacity then stops
  task fill_fifo();
    fifo_seq_item seq_item;                             /* sequence item to be send to the DUT */
    grant_in_e temp;                                    /* current bandwidth */
    
    temp = grant_in_ctrl;
    grant_in_ctrl = BW_000;                             /* set bandwidth to 0%, enabling fifo filling up */
    
    repeat (FIFO_DEPTH) begin
      seq_item = new();
      VALID_RANDOMIZATION: assert (randomize(seq_item))
      else $error("Sequence item randomization failed");
      send_seq_item(seq_item);
    end
    
    grant_in_ctrl = temp;                               /* reset fifo bandwidth */
  endtask: fill_fifo
  
  // waits for enough time to let the DUT free its memory
  task empty_fifo();
    grant_in_e temp;                                    /* current bandwidth */
    
    temp = grant_in_ctrl;
    grant_in_ctrl = BW_100;                             /* set bandwidth to 100%, enabling fifo emptying */
    
    repeat (FIFO_DEPTH) begin
      @(posedge fifo_if_inst.clk);                      /* wait enough clock cycles for the fifo to empty */
    end
    
    grant_in_ctrl = temp;                               /* reset fifo bandwidth */
  endtask: empty_fifo
endmodule: fifo_trafic_gen
