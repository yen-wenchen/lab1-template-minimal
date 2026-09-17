module Debounce (
	input  i_in,
	input  i_clk,
	input  i_rst,
	output o_debounced,
	output o_neg,
	output o_pos
);

parameter CNT_N = 7;
localparam CNT_BIT = $clog2(CNT_N+1);

logic o_debounced_r, o_debounced_w;
logic [CNT_BIT-1:0] counter_r, counter_w;
logic neg_r, neg_w, pos_r, pos_w;

assign o_debounced = o_debounced_r;
assign o_pos = pos_r;
assign o_neg = neg_r;

always_comb begin
	if (i_in != o_debounced_r) begin
		counter_w = counter_r - 1;
	end else begin
		counter_w = CNT_N;
	end
	// modification: do not toggle if the input returned to its old level as the count expired.
	if ((counter_r == 0) && (i_in != o_debounced_r)) begin
		o_debounced_w = ~o_debounced_r;
	end else begin
		o_debounced_w = o_debounced_r;
	end
	pos_w = ~o_debounced_r &  o_debounced_w; // detect i_in posedge
	neg_w =  o_debounced_r & ~o_debounced_w; // detect i_in negedge
end

always_ff @(posedge i_clk or posedge i_rst) begin
	if (i_rst) begin
		o_debounced_r <= '0;
		// modification: start with a full count to prevent a false press just after reset
		counter_r <= CNT_N;
		neg_r <= '0;
		pos_r <= '0;
	end else begin
		o_debounced_r <= o_debounced_w;
		counter_r <= counter_w;
		neg_r <= neg_w;
		pos_r <= pos_w;
	end
end

endmodule
