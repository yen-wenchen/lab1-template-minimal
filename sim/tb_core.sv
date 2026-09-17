`timescale 1ns/1ps
module tb_core;
 reg clk=0; always #5 clk=~clk;
 reg rst=1, start=0;
 wire [3:0] value;
 wire scan;
 Top #(.BASE_BITS(4)) dut(clk,rst,start,value);
 task cycles(input integer n);
   repeat(n) begin @(posedge clk); #1; end
 endtask
 task reset;
   @(negedge clk); rst=1; start=0;
   cycles(3);
   if(value!==0 || dut.running!==0) $fatal(1,"reset");
   @(negedge clk); rst=0;
 endtask
 function [6:0] glyph(input integer d);
 case(d)
 0:glyph=7'h40; 1:glyph=7'h79; 2:glyph=7'h24; 3:glyph=7'h30;
 4:glyph=7'h19; 5:glyph=7'h12; 6:glyph=7'h02; 7:glyph=7'h78;
 8:glyph=7'h00; 9:glyph=7'h10; default:glyph=7'h7f;
 endcase
 endfunction
 integer seed,k,j,expected,elapsed,seen,final_seen=0,saved;
 initial begin
  for(seed=0;seed<16;seed=seed+1) begin
   reset();
   @(negedge clk);
   while(dut.timer !== seed[3:0]) @(negedge clk);
   start=1;
   cycles(1);
   if(value!==seed[3:0]) $fatal(1,"seed %0d got %0d",seed,value);
   start=0;
   expected=seed; seen=1<<seed;
   for(k=1;k<=15;k=k+1) begin
    for(j=1;j<=16*k;j=j+1) begin
     // Busy start must not change the current run or its timing.
     @(negedge clk); start=(j==2);
     cycles(1);
     if(j==16*k) begin
      expected=((expected<<1)&15) | (((expected>>3)^(expected>>2)^((expected&7)==0))&1);
      seen=seen | (1<<expected);
     end
     if(value!==expected[3:0]) $fatal(1,"interval/sequence seed=%0d k=%0d j=%0d",seed,k,j);
    end
   end
   @(negedge clk); start=0;
   if(dut.running!==0 || seen!=65535) $fatal(1,"stop/coverage");
   final_seen=final_seen | (1<<value);
   saved=value; cycles(100);
   if(value!==saved[3:0]) $fatal(1,"hold");
   @(negedge clk); start=1; cycles(1);
   if(!dut.running) $fatal(1,"restart");
   @(negedge clk); start=0;
  end
  if(final_seen!=65535) $fatal(1,"final outcomes not all reachable");
  // Reset interrupts the roll at each stage.
  for(k=0;k<15;k=k+1) begin
   reset(); @(negedge clk); start=1; cycles(1);
   @(negedge clk); start=0;
   cycles(16*k*(k+1)/2+1);
   reset(); cycles(20);
   if(value!==0 || dut.running) $fatal(1,"reset hold");
  end
  $display("PASS: 16 seeds, 16 final outcomes, all increasing intervals, busy start, stop, restart, reset at every stage");
  $finish;
 end
 initial begin #2000000; $fatal(1,"timeout"); end
endmodule
