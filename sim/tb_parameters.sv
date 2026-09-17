`timescale 1ns/1ps
module parameter_case #(parameter N=15, S=1)(output reg done=0);
 reg clk=0; always #5 clk=~clk;
 reg rst=1,start=0;
 wire [3:0] q;
 Top #(.BASE_BITS(4),.NUM_STAGES(N),.SLOWDOWN_STEP(S)) dut(clk,rst,start,q);
 integer k,j,expected;
 initial begin
  repeat(3) @(negedge clk);
  rst=0;
  @(negedge clk); start=1;
  @(posedge clk); #1; expected=q; start=0;
  for(k=0;k<N;k=k+1) begin
   for(j=1;j<=16*(1+k*S);j=j+1) begin
    @(posedge clk); #1;
    if(j==16*(1+k*S))
     expected=((expected<<1)&15)|(((expected>>3)^(expected>>2)^((expected&7)==0))&1);
    if(q!==expected[3:0]) $fatal(1,"N=%0d S=%0d stage=%0d cycle=%0d",N,S,k,j);
    if(dut.running !== ((k==N-1 && j==16*(1+k*S))?1'b0:1'b1))
     $fatal(1,"stop timing N=%0d S=%0d",N,S);
   end
  end
  repeat(50) begin
   @(posedge clk); #1;
   if(q!==expected[3:0] || dut.running) $fatal(1,"hold");
  end
  done=1;
 end
endmodule
module tb_parameters;
 wire [5:0] done;
 parameter_case #(.N(1), .S(1)) a(done[0]);
 parameter_case #(.N(2), .S(3)) b(done[1]);
 parameter_case #(.N(15),.S(1)) c(done[2]);
 parameter_case #(.N(16),.S(2)) d(done[3]);
 parameter_case #(.N(20),.S(3)) e(done[4]);
 parameter_case #(.N(3), .S(8)) f(done[5]);
 initial begin
  wait(&done);
  $display("PASS: parameter cases (stages, step) = (1,1), (2,3), (15,1), (16,2), (20,3), (3,8)");
  $finish;
 end
 initial begin #1000000; $fatal(1,"timeout"); end
endmodule
