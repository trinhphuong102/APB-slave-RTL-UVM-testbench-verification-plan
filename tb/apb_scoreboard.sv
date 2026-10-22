class apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(apb_scoreboard)

    uvm_analysis_imp #(apb_transaction, apb_scoreboard) item_collected_export;

    bit [31:0] exp_sys_ctrl;
    bit [31:0] exp_data_in;

    int pass_count = 0;
    int fail_count = 0;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        item_collected_export = new("item_collected_export", this);
    endfunction

    virtual function void write(apb_transaction trans);
        bit [31:0] expected_data;
        bit        expected_err = 1'b0;

        if (trans.pwrite) begin
            if (trans.paddr[7:0] == 8'h00) begin
                exp_sys_ctrl = trans.pwdata;
            end
            else if (trans.paddr[7:0] == 8'h08) begin
                exp_data_in = trans.pwdata;
            end
            else begin
                expected_err = 1'b1;
            end

            if (trans.pslverr !== expected_err) begin
                `uvm_error("SCB_FAIL", $sformatf("Lỗi cờ pslverr khi GHI! Expected=%0b, Actual=%0b", expected_err, trans.pslverr))
                fail_count++;
            end
        end else begin
            case (trans.paddr[7:0])
                8'h00: expected_data = exp_sys_ctrl;
                8'h04: expected_data = 32'hCAFE_BABE;
                8'h08: expected_data = exp_data_in;
                8'h0C: expected_data = (exp_sys_ctrl[0]) ? ~exp_data_in : exp_data_in;
                default: begin
                    expected_data = 32'h0000_0000;
                    expected_err = 1'b1;
                end
            endcase

            if (trans.prdata === expected_data && trans.pslverr === expected_err) begin
                `uvm_info("SCB_PASS", $sformatf("PASS! paddr=0x%0h | Data=0x%0h | Err=%0b", trans.paddr, trans.prdata, trans.pslverr), UVM_LOW)
                pass_count++;
            end else begin
                `uvm_error("SCB_FAIL", $sformatf("FAIL! paddr=0x%0h | Exp Data=0x%0h, Act Data=0x%0h | Exp Err=%0b, Act Err=%0b", trans.paddr, expected_data, trans.prdata, expected_err, trans.pslverr))
                fail_count++;
            end
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB_REPORT", "=========================================", UVM_NONE)
        `uvm_info("SCB_REPORT", $sformatf(" BÁO CÁO SCOREBOARD: PASS = %0d | FAIL = %0d", pass_count, fail_count), UVM_NONE)
        `uvm_info("SCB_REPORT", "=========================================", UVM_NONE)
    endfunction

endclass