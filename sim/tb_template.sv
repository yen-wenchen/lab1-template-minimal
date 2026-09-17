`timescale 1ns/1ps
module tb_template;
reg clk=0; always #5 clk=~clk;
reg rst=1, button=0;
wire [7:0] an;
wire [6:0] seg;
wire dp;
NEXYS_A7 board(.CLK100MHZ(clk),.BTNC(rst),.BTNU(button),
 .AN(an),.CA(seg[0]),.CB(seg[1]),.CC(seg[2]),.CD(seg[3]),
 .CE(seg[4]),.CF(seg[5]),.CG(seg[6]),.DP(dp));
defparam board.deb0.CNT_N=7;
defparam board.top0.BASE_BITS=4;
integer presses=0;
always @(negedge clk) if(board.BTNU_down) presses=presses+1;
task cycles(input integer n);
 repeat(n) begin @(posedge clk); #1; end
endtask
function [6:0] glyph(input integer n);
 case(n)
 0:glyph=7'h40; 1:glyph=7'h79; 2:glyph=7'h24; 3:glyph=7'h30;
 4:glyph=7'h19; 5:glyph=7'h12; 6:glyph=7'h02; 7:glyph=7'h58;
 8:glyph=7'h00; 9:glyph=7'h10; default:glyph=7'h7f;
 endcase
endfunction
integer n,k,mask;
reg [3:0] forced_value;
initial begin
 cycles(3); @(negedge clk); rst=0; cycles(30);
 if(presses!=0 || board.top0.running || board.random_value!==0)
   $fatal(1,"reset produced phantom start");
 @(negedge clk); button=1; cycles(3);
 @(negedge clk); button=0; cycles(25);
 if(presses!=0) $fatal(1,"short glitch accepted");
 @(negedge clk); button=1; cycles(2000);
 if(presses!=1 || board.top0.running) $fatal(1,"press/stop/held start");
 @(negedge clk); button=0; cycles(3);
 @(negedge clk); button=1; cycles(25);
 if(presses!=1 || !board.deb0.o_debounced) $fatal(1,"release bounce");
 @(negedge clk); button=0; cycles(25);
 @(negedge clk); button=1; cycles(25);
 if(presses!=2 || !board.top0.running) $fatal(1,"second press");
 @(negedge clk); rst=1; button=0; cycles(3);
 @(negedge clk); rst=0; cycles(25);
 if(board.random_value!==0 || presses!=2) $fatal(1,"reset during roll");
 // Isolate unchanged display and completed board wiring; scan naturally.
 force board.random_value=forced_value;
 for(n=0;n<16;n=n+1) begin
  forced_value=n; mask=0;
  for(k=0;k<8010;k=k+1) begin
   cycles(1);
   if(dp!==1) $fatal(1,"DP");
   if(board.digit0!==(n%10) || board.digit1!==(n>=10?1:10))
      $fatal(1,"decimal wiring %0d",n);
   case(board.seven0.state_r)
    0: begin
     mask=mask|1;
     if(an!==8'hfe || seg!==glyph(n%10)) $fatal(1,"ones %0d",n);
    end
    1: begin
     mask=mask|2;
     if(an!==(n>=10?8'hfd:8'hff) || seg!==glyph(n>=10?1:10)) $fatal(1,"tens %0d",n);
    end
    default: if(an!==8'hff) $fatal(1,"unused digit enabled");
   endcase
  end
  if(mask!=3) $fatal(1,"incomplete scan");
 end
 release board.random_value;
 $display("PASS: original template scan/decoder 0..15, board wiring, DP, reset, synchronization, debounce, bounce, hold, second press");
 $finish;
end
initial begin #2000000; $fatal(1,"timeout"); end
endmodule
