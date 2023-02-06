/////////////////////////////////////////////////////////
//
//  FIFO testbench package
//
/////////////////////////////////////////////////////////

package fifo_tb_pkg;
  `include "fifo_seq_item.svh"                          /* model of the fifo transaction */
  
  typedef enum bit [1:0] {
    BW_000, 
    BW_050, 
    BW_100
  } grant_in_e;                                         /* grant_in modes of operation */
endpackage: fifo_tb_pkg
