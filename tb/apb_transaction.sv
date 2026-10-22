class apb_transaction extends uvm_sequence_item;
    rand bit [31:0] paddr;
    rand bit [31:0] pwdata;
    rand bit pwrite;

    bit [31:0] prdata;
    bit pslverr;

    `uvm_object_utils_begin(apb_transaction)
        `uvm_field_int(paddr,   UVM_ALL_ON)
        `uvm_field_int(pwrite,  UVM_ALL_ON)
        `uvm_field_int(pwdata,  UVM_ALL_ON)
        `uvm_field_int(prdata,  UVM_ALL_ON)
        `uvm_field_int(pslverr, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "apb_transaction");
        super.new(name);
    endfunction

    constraint addr_c {
        paddr [1:0] == 2'b00;
    }
    
    constraint c_corner_cases {
        paddr dist {
           32'h00 := 3,
           32'h04 := 1,     
           32'h08 := 3,
           32'h0C := 1,
           
           [32'h10:32'hFF] :/ 2
        };
    }

endclass