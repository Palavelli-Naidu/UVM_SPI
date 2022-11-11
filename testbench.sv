// Code your testbench here
// or browse Examples
// Code your testbench here
// or browse Examples





import uvm_pkg::*;
`include "uvm_macros.svh"


class spi_sequence_item extends uvm_sequence_item;
  
  bit newdata;
  bit cs;
  bit mosi;
  rand bit[11:0] datain;
  
  function new(string name="spi_sequence_item");
    super.new(name);
  endfunction
  
  `uvm_object_utils_begin(spi_sequence_item)
  `uvm_field_int(newdata,UVM_ALL_ON)
  `uvm_field_int(cs,UVM_ALL_ON)
  `uvm_field_int(mosi,UVM_ALL_ON)
  `uvm_field_int(datain,UVM_ALL_ON)
  `uvm_object_utils_end
  
 
  
endclass





class spi_squence extends uvm_sequence#(spi_sequence_item);
  `uvm_object_utils(spi_squence);
  spi_sequence_item trans;
  
  function new(string name="spi_squence");
    super.new(name);
  endfunction
  
  virtual task body();
   
   repeat(10)
     
    begin
   `uvm_info(get_type_name(),"New transaction::::",UVM_LOW);
     
    trans=spi_sequence_item::type_id::create("trans");
    
    wait_for_grant();
    
    trans.randomize();
    
    send_request(trans);
    
    wait_for_item_done();
    end
    
  endtask
    
  endclass
    
  
    
    
    
    
class spi_squencer extends uvm_sequencer#(spi_sequence_item);
  `uvm_component_utils(spi_squencer);

   function new(string name="dff_squencer",uvm_component parent);
   super.new(name,parent);
   endfunction
   
 endclass
    
 


   
    

class spi_driver extends uvm_driver#(spi_sequence_item);
  
  `uvm_component_utils(spi_driver);
  virtual IF if1;
  spi_sequence_item trans;
  
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    uvm_config_db#(virtual IF)::get(this,"","if1",if1);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    
    reset();
    
      forever
        begin
        seq_item_port.get_next_item(trans);
        trans.print();
          
        drive();

        seq_item_port.item_done();
        end
 endtask
  
  
  
  
  virtual task reset();   
    if1.reset=1'b1;
    repeat(5)@(posedge if1.sclk);
    if1.reset=1'b0;
    @(posedge if1.sclk);
     $display("*********reset is done***********");
  endtask
  
  
  
  virtual task drive();
        if1.newdata=1'b1;
        if1.datain=trans.datain;
        
        @(posedge if1.sclk);  //here the data transferss
        #2 if1.newdata=1'b0;
        
        ///waiting until the transaction complected
        
        wait(if1.cs==1'b1);
        @(posedge if1.sclk);
   endtask
  
endclass
    



  
    
class spi_monitor extends uvm_monitor;
  `uvm_component_utils(spi_monitor);
  
  virtual IF if1;
  
  spi_sequence_item trans_trf;
  spi_sequence_item trans_ref;

  uvm_analysis_port#(spi_sequence_item) mon_port_trf;// Analysis port
  uvm_analysis_port#(spi_sequence_item) mon_port_ref;// Analysis port

  
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    uvm_config_db#(virtual IF)::get(this,"","if1",if1);
    trans_trf=spi_sequence_item::type_id::create("trans_trf");
    trans_ref=spi_sequence_item::type_id::create("trans_ref");
    
    mon_port_trf=new("mon_port_trf",this);
    mon_port_ref=new("mon_port_ref",this);
 endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever
      begin

         wait(if1.newdata==1'b1);
         trans_ref.datain=if1.datain;  
         mon_port_ref.write(trans_ref);
         trans_ref.print();


        wait(if1.cs==1'b0);
        
            @(posedge if1.sclk);
        
                for(int i=0;i<12;i++)
                begin
                @(posedge if1.sclk)
                trans_trf.datain[i]=if1.mosi;
                end

             trans_trf.print();
             mon_port_trf.write(trans_trf);

        wait(if1.cs==1'b1);
        
    end
  endtask
  
    
endclass
    




class spi_agent extends uvm_component;
  `uvm_component_utils(spi_agent)
   spi_squencer sqncr;
   spi_driver  drv;
   spi_monitor mon;
  
  
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sqncr=spi_squencer::type_id::create("sqncr",this);
    drv=spi_driver::type_id::create("drv",this);
    mon=spi_monitor::type_id::create("mon",this);
  endfunction
    
        
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqncr.seq_item_export);
  endfunction
  
endclass

    






class spi_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(spi_scoreboard)
       spi_sequence_item tr_ref;
       spi_sequence_item tr_trf;
      
  uvm_analysis_export#(spi_sequence_item) scr_export_ref;
  uvm_analysis_export#(spi_sequence_item) scr_export_trf;
      
  uvm_tlm_analysis_fifo#(spi_sequence_item) fifo_ref;
  uvm_tlm_analysis_fifo#(spi_sequence_item) fifo_trf;
      
       function new(string name,uvm_component parent);
        super.new(name,parent);
       endfunction
      
      
       function void build_phase(uvm_phase phase);
        super.build_phase(phase);
         scr_export_ref=new("spi_export_ref",this); //Analysis export 
         scr_export_trf=new("spi_export_trf",this); //Analysis export 
        
        fifo_ref=new("fifo_ref",this);
        fifo_trf=new("fifo_trf",this);
        
       endfunction
  
      
      function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        scr_export_ref.connect(fifo_ref.analysis_export);
        scr_export_trf.connect(fifo_trf.analysis_export);
      endfunction
      
      
        
    virtual task run_phase(uvm_phase phase);

      forever
          begin
              fifo_ref.get(tr_ref);
              fifo_trf.get(tr_trf);

                      tr_ref.print();
                      tr_trf.print();



            if(tr_ref.datain==tr_trf.datain)
                begin
                  $display("DATA MATCHED");
                end
              else
                begin
                $display("DATA MISMATCHED");
                end
            
          end
      endtask
      
      
    endclass
    







class spi_environment extends uvm_env;
  `uvm_component_utils(spi_environment)

  spi_agent agnt;
  spi_scoreboard scr;

  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agnt=spi_agent::type_id::create("agnt",this);
    scr=spi_scoreboard::type_id::create("scr",this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agnt.mon.mon_port_ref.connect(scr.scr_export_ref);
    agnt.mon.mon_port_trf.connect(scr.scr_export_trf);
  endfunction

endclass

    


    
class spi_test extends uvm_test;
  `uvm_component_utils(spi_test)

  spi_squence squnc;
  spi_environment env;

  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    squnc=spi_squence::type_id::create("squnc");
    env=spi_environment::type_id::create("env",this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    squnc.start(env.agnt.sqncr);
    phase.drop_objection(this);
  endtask


endclass
    
    


  
    
module top;

 
  IF if1();
  
  SPI spi(.newdata(if1.newdata),.sclk(if1.sclk),.datain(if1.datain),.reset(if1.reset),.cs(if1.cs),.mosi(if1.mosi));
  
  always #5 if1.sclk = ~if1.sclk;
  initial
    begin
      if1.sclk=0;
      uvm_config_db#(virtual IF)::set(null,"*","if1",if1);
      run_test("spi_test");
    end


endmodule



















    