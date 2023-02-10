/////////////////////////////////////////////////////////
//
//  FIFO control unit module
//
/////////////////////////////////////////////////////////

module fifo_cu
# (parameter FIFO_DEPTH = 4,                            /* maximum number of fifo elements */
             ADDR_WIDTH = $clog2(FIFO_DEPTH),           /* number of bits needed to represent each fifo element */
             FIFO_SIZE  = $clog2(FIFO_DEPTH+1)          /* number of bits needed to represent the number of elements that can be found in the fifo; note that FIFO_DEPTH+1 values are possible {0, 1, ..., FIFO_DEPTH} */
  )
  (input  logic                  clk, rst_n,
   input  logic                  push_valid_in, pop_grant_in,
   output logic                  push_grant_out, pop_valid_out,
   output logic [ADDR_WIDTH-1:0] rd_addr, wr_addr       /* addresses of the fifo where to read/write data from/to */
  );
  
  // FSM state encoding: Johnson
  typedef enum logic [1:0] {
    RESET  = 2'b00,
    EMPTY  = 2'b10,
    ACTIVE = 2'b11,
    FULL   = 2'b01
  } state_t;
  
  // the state of the machine is represented by three attributes: state, h_addr and fifo_size
  state_t                state, next_state;
  logic [ADDR_WIDTH-1:0] h_addr, next_h_addr;           /* address of the head of the fifo */
  logic [FIFO_SIZE-1:0]  fifo_size, next_fifo_size;     /* number of elements currently stored in the fifo */
  
  // current state logic
  always_ff @ (posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      h_addr    <= '0;
      fifo_size <= '0;
      state     <= RESET;
    end else begin
      h_addr    <= next_h_addr;
      fifo_size <= next_fifo_size;
      state     <= next_state;
    end
  end
  
  // next state logic
  // NOTE: I do assume wrap-around arithmetic enabling representation (e.g. 2's complement).
  //       If this assumption is incorrect, statements:
  //       next_h_addr     = h_addr + 1;
  //       next_fifo_size  = fifo_size + 1;
  //       next_fifo_size  = fifo_size - 1;
  //       should be substituted by:
  //       next_h_addr     = (h_addr + 1) % FIFO_DEPTH;
  //       next_fifo_size  = (fifo_size + 1) % (FIFO_DEPTH + 1);
  //       next_fifo_size  = (fifo_size - 1) % (FIFO_DEPTH + 1);
  always_comb begin
    unique case (state)
      RESET: begin
        next_h_addr    = h_addr;
        next_fifo_size = fifo_size;
        next_state     = EMPTY;
      end
      EMPTY: begin
        next_h_addr      = h_addr;
        if (push_valid_in) begin                        /* push new element onto the empty fifo */
          next_fifo_size = fifo_size + 1;
          next_state     = ACTIVE;
        end else begin
          next_fifo_size = fifo_size;
          next_state     = EMPTY;
        end
      end
      ACTIVE: begin
        if (push_valid_in) begin
          if (pop_grant_in) begin                       /* push and pop */
            next_h_addr    = h_addr + 1;
            next_fifo_size = fifo_size;
            next_state     = ACTIVE;
          end else begin                                /* only push */
            next_h_addr    = h_addr;
            next_fifo_size = fifo_size + 1;
            if (next_fifo_size == FIFO_DEPTH)           /* fifo filled by the new push */
              next_state   = FULL;
            else                                        /* fifo not filled by the new push */
              next_state   = ACTIVE;
          end
        end else begin
          if (pop_grant_in) begin                       /* only pop */
            next_h_addr    = h_addr + 1;
            next_fifo_size = fifo_size - 1;
            if (next_fifo_size == 0)                    /* fifo emptied by the new pop */
              next_state   = EMPTY;
            else                                        /* fifo not emptied by the new pop */
              next_state   = ACTIVE;
          end else begin                                /* no push and no pop */
            next_h_addr    = h_addr;
            next_fifo_size = fifo_size;
            next_state     = ACTIVE;
          end
        end
      end
      FULL: begin
        if (pop_grant_in) begin                         /* remove element out of the full fifo */
          next_h_addr    = h_addr + 1;
          next_fifo_size = fifo_size - 1;
          next_state     = ACTIVE;
        end else begin
          next_h_addr    = h_addr;
          next_fifo_size = fifo_size;
          next_state     = FULL;
        end
      end
    endcase
  end
  
  // output logic: Moore type
  // NOTE: I do assume wrap-around arithmetic enabling representation (e.g. 2's complement).
  //       If this assumption is incorrect, statements:
  //       rd_addr = h_addr;
  //       wr_addr = h_addr + fifo_size;
  //       should be substituted by:
  //       rd_addr = h_addr % FIFO_DEPTH;
  //       wr_addr = (h_addr + fifo_size) % FIFO_DEPTH;
  always_comb begin
    {push_grant_out, pop_valid_out} = state;            /* note how when state = RESET (2'b00) {push_grant_out, pop_valid_out} should be 2'b00, when state = EMPTY (2'b10) {push_grant_out, pop_valid_out} should be 2'b10... */
    rd_addr = h_addr;                                   /* read data from the head of the fifo; fifo is modeled as a cyclic array */
    wr_addr = h_addr + fifo_size;                       /* write data to the "first empty position" (i.e. head of the fifo plus fifo size) of the fifo; fifo is modeled as a cyclic array */
  end
endmodule: fifo_cu
