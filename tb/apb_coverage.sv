class apb_coverage extends uvm_subscriber #(apb_transaction);
    `uvm_component_utils(apb_coverage)

    apb_transaction trans;

    covergroup apb_cg;
        option.per_instance = 1;

        cp_addr: coverpoint trans.paddr {
            bins sys_ctrl   = {32'h00};
            bins sys_status = {32'h04};
            bins data_in    = {32'h08};
            bins data_out   = {32'h0C};
            bins unmapped   = {[32'h10:32'hFF]};
        }

        cp_write: coverpoint trans.pwrite {
            bins read  = {1'b0};
            bins write = {1'b1};
        }

        cp_err: coverpoint trans.pslverr {
            bins no_error = {1'b0};
            bins error    = {1'b1};
        }

        cross_addr_write: cross cp_addr, cp_write;
    endgroup

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        apb_cg = new();
    endfunction

    virtual function void write(apb_transaction t);
        trans = t;
        apb_cg.sample();
    endfunction
    
    virtual function void report_phase(uvm_phase phase);
        real cov_val;
        super.report_phase(phase);
        cov_val = (apb_cg.get_coverage() > 0.0) ? apb_cg.get_coverage() : $get_coverage();
        `uvm_info("COV_REPORT", 
              $sformatf("=================================================="), UVM_NONE)
        `uvm_info("COV_REPORT", 
              $sformatf(" FINAL FUNCTIONAL COVERAGE: %0.2f %%", cov_val), UVM_NONE)
        `uvm_info("COV_REPORT", 
              $sformatf("=================================================="), UVM_NONE)
              
  endfunction

endclass