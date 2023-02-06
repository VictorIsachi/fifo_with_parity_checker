/////////////////////////////////////////////////////////
//
//  FIFO sequence item
//
/////////////////////////////////////////////////////////

typedef enum bit {NO_ERR, BIT_FLIP} error_t;            /* one type of error supported: bit flip */

class fifo_seq_item #(PARITY = 1'b1, P_BIT = 1'b1, DATA_WIDTH = 17);
  // metadata
  static int   global_id = 0;                           /* global transaction counter */
  int          item_id;                                 /* counter of the current transaction */
  rand error_t data_error_type;                         /* indicates whether the current transaction has a fault */
  
  // sequence item data
  rand logic [DATA_WIDTH-1:0] data;
  
  // error distribution constraint
  constraint error_dist_c {data_error_type dist {NO_ERR:=9, BIT_FLIP:=1};}
  
  function new();
    item_id = global_id++;
  endfunction
  
  // calculates and sets the parity bit of the sequence item
  function void set_parity();
    bit parity_bit;
    unique case (1'b1)
      ((data_error_type == NO_ERR) && (PARITY == 1'b1)): 
        parity_bit = 1'b1;                              /* no error, EVEN parity */
      ((data_error_type == NO_ERR) && (PARITY == 1'b0)): 
        parity_bit = 1'b0;                              /* no error, ODD parity */
      ((data_error_type == BIT_FLIP) && (PARITY == 1'b1)): 
        parity_bit = 1'b0;                              /* bit flip, EVEN parity */
      ((data_error_type == BIT_FLIP) && (PARITY == 1'b0)): 
        parity_bit = 1'b1;                              /* bit flip, ODD parity */
    endcase
    if (P_BIT == 1'b1) begin                            /* LSB is the parity bit */
      if (data[DATA_WIDTH-1:1] % 2) begin               /* odd number of 1's */
        this.data[0] = parity_bit;
      end else begin                                    /* even number of 1's */
        this.data[0] = ~parity_bit;
      end
    end else begin                                      /* MSB is the parity bit*/
      if (data[DATA_WIDTH-2:0] % 2) begin               /* odd number of 1's */
        this.data[DATA_WIDTH-1] = parity_bit;
      end else begin                                    /* even number of 1's */
        this.data[DATA_WIDTH-1] = ~parity_bit;
      end
    end
  endfunction: set_parity
  
  function void print_seq_item();
    $display("------------------------------------------");
    $display("FIFO sequence item");
    $display("ID: %0d (Global ID: %0d)", this.item_id, fifo_seq_item::global_id);
    $display("DATA: 0x%0h (0b%0b)", this.data, this.data);
    $display("PARITY: %s", data_error_type == NO_ERR ? "correct" : "wrong");
    $display("------------------------------------------");
  endfunction: print_seq_item
  
  function bit cmp_seq_item(fifo_seq_item seq_item);
    cmp_seq_item = 1'b1;
    for (int i = 0; i < DATA_WIDTH; i++)
      if (this.data[i] != seq_item.data[i])
        cmp_seq_item = 1'b0;
  endfunction: cmp_seq_item
  
  // set parity after randomization call
  function void post_randomize();
    this.set_parity();
  endfunction: post_randomize
endclass: fifo_seq_item
