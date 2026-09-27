// pong_tb.v -- testbench for pong.v
// Run: iverilog -o pong_tb pong.v pong_tb.v && vvp pong_tb

`timescale 1ns / 1ps

module pong_tb;

    reg clk = 0;
    reg rst;
    reg p1_up, p1_down, p2_up, p2_down;
    wire [9:0] ball_x, ball_y, p1_y, p2_y;
    wire signed [9:0] vx, vy;
    wire [3:0] score1, score2;
    wire game_over;

    pong #(
        .W(64), .H(32), .PADDLE_H(6),
        .WIN_SCORE(3), .TICKS_PER_MOVE(2)
    ) dut (
        .clk(clk), .rst(rst),
        .p1_up(p1_up), .p1_down(p1_down),
        .p2_up(p2_up), .p2_down(p2_down),
        .ball_x(ball_x), .ball_y(ball_y),
        .vx(vx), .vy(vy),
        .p1_y(p1_y), .p2_y(p2_y),
        .score1(score1), .score2(score2),
        .game_over(game_over)
    );

    always #5 clk = ~clk;  // 100 MHz

    integer fails = 0;

    task check(input integer cond, input string msg);
        begin
            if (!cond) begin
                $display("FAIL: %s", msg);
                fails = fails + 1;
            end else begin
                $display("PASS: %s", msg);
            end
        end
    endtask

    reg [9:0] bx0;

    initial begin
        p1_up = 0; p1_down = 0; p2_up = 0; p2_down = 0;

        // ---- reset ----
        rst = 1; #20; rst = 0; #10;
        check(ball_x == 32 && ball_y == 16, "reset centers ball");
        check(p1_y == 13 && p2_y == 13, "reset centers paddles");
        check(score1 == 0 && score2 == 0 && game_over == 0, "reset clears score");

        // ---- paddle moves up while held ----
        p1_up = 1; #200; p1_up = 0;
        check(p1_y < 13, "p1 paddle moves up");

        // ---- paddle clamps at top ----
        p1_up = 1; #2000; p1_up = 0;
        check(p1_y == 0, "p1 paddle clamps at top edge");

        // ---- ball advances over time ----
        bx0 = ball_x;
        #500;
        check(ball_x != bx0, "ball moves over time");

        // ---- force a miss: park p1 paddle at bottom, ball near left edge moving left ----
        // (drive DUT state hierarchically between move ticks)
        @(negedge clk);
        dut.p1_y = 26;                 // paddle out of the way (field H=32)
        dut.ball_x = 4; dut.ball_y = 2;
        dut.vx = -1; dut.vy = 0;
        #200;                          // let a few move ticks run
        check(score2 == 1, "player 2 scores when p1 misses");
        check(ball_x == 32, "ball re-served to center after score");

        // ---- wall bounce: ball moving up into top wall flips vy ----
        @(negedge clk);
        dut.ball_x = 32; dut.ball_y = 1;
        dut.vx = 0; dut.vy = -1;
        #100;
        check(dut.vy == 1, "ball bounces off top wall (vy flips)");

        // ---- game over at WIN_SCORE ----
        @(negedge clk);
        dut.score1 = 2;                // one away from WIN_SCORE=3
        dut.ball_x = 60; dut.ball_y = 2;
        dut.vx = 1; dut.vy = 0;
        dut.p2_y = 26;                 // p2 misses
        #200;
        check(score1 == 3, "player 1 reaches winning score");
        check(game_over == 1, "game_over asserted at WIN_SCORE");

        // ---- frozen after game over ----
        bx0 = ball_x; #200;
        check(ball_x == bx0, "ball frozen after game over");

        if (fails == 0) $display("ALL TESTS PASSED");
        else $display("%0d TEST(S) FAILED", fails);
        $finish;
    end

endmodule
