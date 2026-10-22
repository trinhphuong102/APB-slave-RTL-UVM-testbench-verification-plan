class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual apb_if.monitor_mp vif;
    uvm_analysis_port #(apb_transaction) item_collected_port;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_if.monitor_mp)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found in Monitor")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_transaction trans;

        wait (vif.presetn === 1'b1);

        forever begin
            @(vif.cb_monitor);

            if (vif.cb_monitor.psel === 1'b1 && 
                vif.cb_monitor.penable === 1'b1 && 
                vif.cb_monitor.pready === 1'b1) begin
                
                trans = apb_transaction::type_id::create("trans");

                trans.paddr   = vif.cb_monitor.paddr;
                trans.pwrite  = vif.cb_monitor.pwrite;
                trans.pslverr = vif.cb_monitor.pslverr;

                if (vif.cb_monitor.pwrite) begin
                    trans.pwdata = vif.cb_monitor.pwdata;
                end else begin
                    trans.prdata = vif.cb_monitor.prdata;
                end

                item_collected_port.write(trans);
            end
        end
    endtask

endclass