class apb_env extends uvm_env;
    `uvm_component_utils(apb_env)

    apb_agent      agent;
    apb_scoreboard scb;
    apb_coverage   cov;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        agent = apb_agent::type_id::create("agent", this);
        scb   = apb_scoreboard::type_id::create("scb", this);
        cov   = apb_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        agent.monitor.item_collected_port.connect(scb.item_collected_export);
        agent.monitor.item_collected_port.connect(cov.analysis_export);
    endfunction

endclass