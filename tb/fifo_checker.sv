/////////////////////////////////////////////////////////
//
//  FIFO checker
//
/////////////////////////////////////////////////////////

module fifo_checker
# (parameter FIFO_DEPTH = 4,                            /* maximum number of fifo elements */
             DATA_WIDTH = 17,                           /* number of bits of each fifo element */
             PARITY     = 1'b1,                         /* indicates the parity of the checker: 1'b1 for EVEN, 1'b0 for ODD */
             P_BIT      = 1'b1                          /* indicates the position of the parity bit: 1'b1 for LSB, 1'b0 for MSB; note that it is not used in my design */
  )     
  (fifo_if.CHECKER fifo_if_inst
  );
  
  import fifo_tb_pkg::*;
  
  // test statistics
  int passes, fails;
  int pushed_no_err, poped_no_err;
  int pushed_bit_flip, poped_bit_flip; 
  
  fifo_seq_item expected_seq_items[$];                  /* keeps track of the items in the fifo with correct parity bit */
  
  // main loop of the checker
  always @ (posedge fifo_if_inst.clk, negedge fifo_if_inst.rst_n) begin
    if (!fifo_if_inst.rst_n)
      expected_seq_items.delete();
    if (fifo_if_inst.valid_in && fifo_if_inst.grant_out)
      check_data_in();
    if (fifo_if_inst.valid_out && fifo_if_inst.grant_in)
      check_data_out();
  end
  
  // translate the signals sent to the DUT into a fifo_seq_item and proceed accordingly
  function void check_data_in();
    fifo_seq_item seq_item;                             /* data_in sequence item */
    
    seq_item = new();
    seq_item.item_id = -1;                              /* set id to -1 to indicate that is a sequence item related to the checker */
    
    for (int i = 0; i < DATA_WIDTH; i++)
      seq_item.data[i] = fifo_if_inst.data_in[i];
    set_error(seq_item);
    
    $display("Detected FIFO push");
    seq_item.print_seq_item();
    
    if (seq_item.data_error_type == NO_ERR) begin
      expected_seq_items.push_back(seq_item);
      pushed_no_err++;
    end else 
      pushed_bit_flip++;
  endfunction: check_data_in
  
  // translate the signals sent by the DUT into a fifo_seq_item and proceed accordingly
  function void check_data_out();
    fifo_seq_item seq_item;                             /* data_out sequence item */
    
    seq_item = new();
    seq_item.item_id = -1;                              /* set id to -1 to indicate that is a sequence item related to the checker */
    
    for (int i = 0; i < DATA_WIDTH; i++) begin
      seq_item.data[i] = fifo_if_inst.data_out[i];
    end
    set_error(seq_item);
    
    $display("Detected FIFO pop");
    seq_item.print_seq_item();
    
    if (seq_item.data_error_type == NO_ERR) begin
      poped_no_err++;
      compare_seq_items(seq_item);                      /* make sure that the poped sequence item is what was expected */
    end else begin
      poped_bit_flip++;
      fails++;
    end
    print_statistics();
  endfunction: check_data_out
  
  // computes and sets the parity bit of the sequence item
  function automatic void set_error(ref fifo_seq_item seq_item);
    bit disparity;
    disparity = ^seq_item.data;
    if (PARITY ^ disparity)                             /* correct parity */
      seq_item.data_error_type = NO_ERR;
    else                                                /* wrong parity */
      seq_item.data_error_type = BIT_FLIP;
  endfunction: set_error
  
  // compare the sequence item sent by the DUT with what the checker is expecting and proceed accordingly
  function void compare_seq_items(fifo_seq_item seq_item);
    fifo_seq_item expected_seq_item;                    /* sequence item that the checker expects the DUT to send */
    bit equal;                                          /* indicates that the sequence item sent by the DUT is equal to the sequence item in the ckecker queue */
    
    do begin                                            /* pop elements from the checker queue until the one sent by the DUT is found; this is done to account for data loss */
      expected_seq_item = expected_seq_items.pop_front();
      equal = 1;
      
      for (int i = 0; i < DATA_WIDTH; i++)
        if (seq_item.data[i] != expected_seq_item.data[i])
          equal = 0;
      
      if (equal)
        passes++;
      else
        fails++;
    end while (!equal);
  endfunction
  
  function void print_statistics();
    $display("******************************************");
    $display("Statistics:");
    $display("Passes/Fails: %0d/%0d", passes, fails);
    $display("Pushed/Poped with no error: %0d/%0d", pushed_no_err, poped_no_err);
    $display("Pushed/Poped with bit flip: %0d/%0d", pushed_bit_flip, poped_bit_flip);
    $display("******************************************");
  endfunction
endmodule: fifo_checker
