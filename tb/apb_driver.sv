class apb_driver extends uvm_driver #(apb_transaction);
    virtual apb_if.driver_mp vif;

    `uvm_component_utils(apb_driver)

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_if.driver_mp)::get(this, "", "vif", vif)) begin 
            `uvm_fatal("NO_VIF", "Virtual interface not found")
        end
    endfunction

    task run_phase(uvm_phase phase);

        vif.cb_driver.psel    <= 1'b0;
        vif.cb_driver.penable <= 1'b0;
        vif.cb_driver.pwrite  <= 1'b0;
        forever begin
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_transfer(apb_transaction trans);
        @ (vif.cb_driver);

        vif.cb_driver.paddr  <= trans.paddr;
        vif.cb_driver.pwrite <= trans.pwrite;

        if (trans.pwrite) begin
            vif.cb_driver.pwdata <= trans.pwdata;
        end

        vif.cb_driver.psel    <= 1'b1;
        vif.cb_driver.penable <= 1'b0;
        
        @ (vif.cb_driver);
        vif.cb_driver.penable <= 1'b1;
        wait (vif.cb_driver.pready === 1'b1);

        if (!trans.pwrite) begin
            trans.prdata = vif.cb_driver.prdata;
        end
        
        trans.pslverr = vif.cb_driver.pslverr;

        @ (vif.cb_driver);
        vif.cb_driver.psel    <= 1'b0;
        vif.cb_driver.penable <= 1'b0;
        
    endtask

endclass