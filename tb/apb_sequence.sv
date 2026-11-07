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
                req.paddr = 32'h00;
                req.pwrite = 1'b1;
                req.pwdata = $urandom();
                req.pwdata[0] = 1'b1;
                finish_item(req);

                req = apb_transaction::type_id::create("req");
                start_item(req);
                req.paddr = 32'h08;
                req.pwrite = 1'b1;
                req.pwdata = $urandom();
                finish_item(req);
            end

            TEST_READ_ALL: begin
                `uvm_info("SEQ", "Running Mode: TEST_READ_ALL (Scanning all valid registers)", UVM_LOW)
                
                foreach (addr_list[i]) begin
                    req = apb_transaction::type_id::create("req");
                    start_item(req);
                    req.paddr = addr_list[i];
                    req.pwrite = 1'b0;
                    finish_item(req);
                end
            end

            TEST_ERROR_HANDLING: begin
                `uvm_info("SEQ", "Running Mode: TEST_ERROR_HANDLING (Testing pslverr response)", UVM_LOW)
                
                req = apb_transaction::type_id::create("req");
                start_item(req);
                req.paddr = 32'h14;
                req.pwrite = 1'b1;
                req.pwdata = $urandom();
                finish_item(req);

                req = apb_transaction::type_id::create("req");
                start_item(req);
                req.paddr = 32'h20;
                req.pwrite = 1'b0;
                finish_item(req);
            end

            TEST_RANDOM_STRESS: begin
                `uvm_info("SEQ", $sformatf("Running Mode: TEST_RANDOM_STRESS (Executing %0d random transactions)", loop_count), UVM_LOW)
                
                repeat(loop_count) begin
                    int r;
                    req = apb_transaction::type_id::create("req");
                    start_item(req);
                    req.pwrite = $urandom_range(0, 1);
                    req.pwdata = $urandom();
                    r = $urandom_range(0, 9);
                    if (r < 3) req.paddr = 32'h00;
                    else if (r < 4) req.paddr = 32'h04;
                    else if (r < 7) req.paddr = 32'h08;
                    else if (r < 8) req.paddr = 32'h0C;
                    else req.paddr = ($urandom_range(32'h10, 32'hFF) & ~32'h3);
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