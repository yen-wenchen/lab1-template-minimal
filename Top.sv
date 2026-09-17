module Top #(
    parameter integer NUM_STAGES = 15, // # of random values to display
    parameter integer SLOWDOWN_STEP = 1, // # of ticks to wait before the next random value
    parameter integer BASE_BITS = 22 // # of bits timer holds
)(
    input logic i_clk,
    input logic i_rst,
    input logic i_start,
    output logic [3:0] o_random_out
);
    logic [BASE_BITS-1:0] timer;

    localparam integer STAGE_BITS = (NUM_STAGES > 1) ? $clog2(NUM_STAGES) : 1;
    localparam integer MAX_WAIT = (NUM_STAGES - 1) * SLOWDOWN_STEP;
    localparam integer WAIT_BITS = (MAX_WAIT > 0) ? $clog2(MAX_WAIT + 1) : 1;

    logic [STAGE_BITS-1:0] stage;       // # of random values shown so far
    logic [WAIT_BITS-1:0] remaining;    // # of ticks countdown before next random
    logic running;                      // is runing or not
    logic tick;

    assign tick = &timer;               // tick == 1 iff all digits of timer == 1

    logic [3:0] next_random;

    assign next_random = {o_random_out[2:0], o_random_out[3] ^ o_random_out[2] ^ (~|o_random_out[2:0])};
    
    
    // main sequential logic
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            timer <= 0;
            stage <= 0;
            remaining <= 0;
            running <= 0;
            o_random_out <= 0;
        end else begin
            timer <= timer + 1'b1;

            if (i_start && !running) begin // start a new roll (ignore presses during a roll)
                o_random_out <= timer[3:0];
                timer <= 0;
                stage <= 0;
                remaining <= 0;
                running <= 1;
            end else if (running && tick) begin //
                if (remaining != 0) begin
                    remaining <= remaining - 1'b1;
                end else begin // remaining == 0
                    o_random_out <= next_random; // roll out

                    if (stage == NUM_STAGES - 1) begin
                        running <= 0;
                    end else begin
                        // next stage (roll a new number & reset remaining)
                        stage <= stage + 1'b1;
                        remaining <= (stage + 1) * SLOWDOWN_STEP;
                    end
                end
            end
        end
    end
endmodule
