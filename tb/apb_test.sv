`include "uvm_macros.svh"
import uvm_pkg::*;

class apb_test extends uvm_test;
    `uvm_component_utils(apb_test)

    apb_env env;

    function new(string name = "apb_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = apb_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("TEST", "UVM Topology:", UVM_LOW)
        this.print();
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_sequence seq;

        phase.raise_objection(this);
        
        `uvm_info("TEST", "--- STAGE 1: RUNNING TEST_CONFIG_ACTIVE ---", UVM_LOW)

        seq = apb_sequence::type_id::create("seq");
        seq.mode = TEST_CONFIG_ACTIVE; 
        seq.start(env.agent.sequencer);

        `uvm_info("TEST", "--- STAGE 2: RUNNING TEST_READ_ALL ---", UVM_LOW)
        seq = apb_sequence::type_id::create("seq");
        seq.mode = TEST_READ_ALL; 
        seq.start(env.agent.sequencer);
        
        `uvm_info("TEST", "--- STAGE 3: RUNNING TEST_ERROR_HANDLING ---", UVM_LOW)
        seq = apb_sequence::type_id::create("seq");
        seq.mode = TEST_ERROR_HANDLING;
        seq.start(env.agent.sequencer);

        `uvm_info("TEST", "--- STAGE 4: RUNNING TEST_RANDOM_STRESS ---", UVM_LOW)
        seq = apb_sequence::type_id::create("seq");
        seq.mode = TEST_RANDOM_STRESS;
        seq.loop_count = 100;
        seq.start(env.agent.sequencer);

        #100ns; 
    
        `uvm_info("TEST", "=======================================", UVM_LOW)
        `uvm_info("TEST", "  END MASTER SEQUENCE", UVM_LOW)
        `uvm_info("TEST", "=======================================", UVM_LOW)

        phase.drop_objection(this);

    endtask

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COVERAGE", $sformatf("Total Functional Coverage = %0.2f %%", $get_coverage()), UVM_LOW)
    endfunction
    
endclass