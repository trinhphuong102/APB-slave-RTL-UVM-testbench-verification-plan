class apb_sequence extends uvm_sequence #(apb_transaction);
    `uvm_object_utils(apb_sequence)

    test_mode mode = TEST_RANDOM_STRESS;
    int unsigned loop_count = 20;
    
    function new(string name = "apb_sequence");
        super.new(name);
    endfunction

    virtual task body();
        apb_transaction req;
        bit [31:0] addr_list[4] = '{32'h00, 32'h04, 32'h08, 32'h0C};

        `uvm_info("SEQ", $sformatf("=== STARTING SEQUENCE WITH MODE: %0s ===", mode.name()), UVM_LOW)

        case (mode)
            TEST_CONFIG_ACTIVE: begin
                `uvm_info("SEQ", "Running Mode: TEST_CONFIG_ACTIVE (Activate bit inversion)", UVM_LOW)
                
                req = apb_transaction::type_id::create("req");
                start_item(req);
                if (!req.randomize() with { paddr == 32'h00; pwrite == 1'b1; pwdata[0] == 1'b1; }) begin
                    `uvm_error("SEQ_RAND_FAIL", "Randomization failed: Cannot generate data to activate sys_ctrl!")
                end
                finish_item(req);

                req = apb_transaction::type_id::create("req");
                start_item(req);
                if (!req.randomize() with { paddr == 32'h08; pwrite == 1'b1; }) begin
                    `uvm_error("SEQ_RAND_FAIL", "Randomization failed: Cannot generate data for data_in!")
                end
                finish_item(req);
            end

            TEST_READ_ALL: begin
                `uvm_info("SEQ", "Running Mode: TEST_READ_ALL (Scanning all valid registers)", UVM_LOW)
                
                foreach (addr_list[i]) begin
                    req = apb_transaction::type_id::create("req");
                    start_item(req);
                    if (!req.randomize() with { paddr == addr_list[i]; pwrite == 1'b0; }) begin
                        `uvm_error("SEQ_RAND_FAIL", $sformatf("Randomization failed: Cannot generate READ cmd for paddr=0x%0h", addr_list[i]))
                    end
                    finish_item(req);
                end
            end

            TEST_ERROR_HANDLING: begin
                `uvm_info("SEQ", "Running Mode: TEST_ERROR_HANDLING (Testing pslverr response)", UVM_LOW)
                
                req = apb_transaction::type_id::create("req");
                start_item(req);
                if (!req.randomize() with { paddr == 32'h14; pwrite == 1'b1; }) begin
                    `uvm_error("SEQ_RAND_FAIL", "Randomization failed: Cannot generate invalid WRITE cmd!")
                end
                finish_item(req);

                req = apb_transaction::type_id::create("req");
                start_item(req);
                if (!req.randomize() with { paddr == 32'h20; pwrite == 1'b0; }) begin
                    `uvm_error("SEQ_RAND_FAIL", "Randomization failed: Cannot generate invalid READ cmd!")
                end
                finish_item(req);
            end

            TEST_RANDOM_STRESS: begin
                `uvm_info("SEQ", $sformatf("Running Mode: TEST_RANDOM_STRESS (Executing %0d random transactions)", loop_count), UVM_LOW)
                
                repeat(loop_count) begin
                    req = apb_transaction::type_id::create("req");
                    start_item(req);
                    if (!req.randomize()) begin
                        `uvm_error("SEQ_RAND_FAIL", "Randomization failed: Cannot generate random data!")
                    end
                    finish_item(req);
                end
            end

            default: begin
                `uvm_error("SEQ_MODE_ERR", $sformatf("Invalid test_mode: %0s", mode.name()))
            end
        endcase

        `uvm_info("SEQ", "=== SEQUENCE EXECUTION COMPLETED ===", UVM_LOW)
    endtask

endclass