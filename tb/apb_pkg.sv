package apb_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  typedef enum {
      TEST_CONFIG_ACTIVE,
      TEST_READ_ALL,
      TEST_ERROR_HANDLING,
      TEST_RANDOM_STRESS
  } test_mode;

  `include "apb_transaction.sv"
  `include "apb_sequence.sv"
  `include "apb_driver.sv"
  `include "apb_monitor.sv"
  `include "apb_scoreboard.sv"
  `include "apb_coverage.sv"
  `include "apb_agent.sv"
  `include "apb_env.sv"
  `include "apb_test.sv"
endpackage