// Code your design here



// Code your design here
// Code your design here


module SPI(input newdata,input sclk,input [11:0]datain,input reset,output reg cs,output reg mosi);
  
  parameter idle=2'b00,send=2'b01;
  int counter=0;
  int count=0;
  reg [1:0] PS;
  reg [1:0] NS;
  reg [11:0] temp;
  
  
  
  always@(posedge sclk)
    begin
      if(reset==1'b1)
          begin
            cs=1'b1;
            mosi=1'b0;
            PS=idle;
          end

       else PS=NS;
    end
  
  
  always @(PS,posedge sclk)
    begin
      case(PS)
        
        idle:begin 
                   if(newdata==1'b1)
                       begin
                         cs=1'b0;
                         temp=datain;
                         count=0;
                         NS=send;
                       end
                   else
                       begin
                         cs=1'b1;
                         NS=idle;
                       end
              end
        
        send:begin 
                   if(count<12)
                       begin 
                         mosi=temp[count];
                         count=count+1;
                         NS=send;
                       end
                   else 
                       begin 
                         cs=1'b1;
                         mosi=1'b0;
                         NS=idle;
                       end
              end  
          
        default: begin 
                 NS=idle;
                 end
        
      endcase
    end
  
  
endmodule                     
  
 


interface IF;
  logic newdata;
  logic [11:0] datain;
  logic reset;
  logic cs;
  logic sclk;
  logic mosi;
endinterface

