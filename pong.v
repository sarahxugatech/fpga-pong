// pong.v -- Pong game logic in Verilog (simulation model, no VGA).
//
// Field: W x H logical pixels. Ball bounces off top/bottom walls and paddles.
// Missing a paddle scores for the opponent; first to WIN_SCORE wins.
//
// Controls are level-sensitive: hold p1_up to move player-1 paddle up, etc.
// Ball advances one pixel every TICKS_PER_MOVE clock cycles.

module pong #(
    parameter W               = 64,
    parameter H               = 32,
    parameter PADDLE_H        = 6,
    parameter WIN_SCORE       = 5,
    parameter TICKS_PER_MOVE  = 10
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             p1_up,
    input  wire             p1_down,
    input  wire             p2_up,
    input  wire             p2_down,
    output reg  [9:0]       ball_x,
    output reg  [9:0]       ball_y,
    output reg  signed [9:0] vx,
    output reg  signed [9:0] vy,
    output reg  [9:0]       p1_y,
    output reg  [9:0]       p2_y,
    output reg  [3:0]       score1,
    output reg  [3:0]       score2,
    output reg              game_over
);

    reg [15:0] tick_cnt;
    wire move_tick = (tick_cnt == TICKS_PER_MOVE - 1);

    // ---- next-state (combinational) ----
    reg signed [10:0] nx, ny, nvx, nvy;
    reg scored;            // someone scored this tick
    reg score_p1;          // 1 => player1 scored, 0 => player2 scored

    always @(*) begin
        nx = $signed({1'b0, ball_x}) + vx;
        ny = $signed({1'b0, ball_y}) + vy;
        nvx = vx;
        nvy = vy;
        scored = 1'b0;
        score_p1 = 1'b0;

        // top / bottom wall bounce
        if (ny < 0) begin
            ny = 0;
            nvy = -vy;
        end else if (ny >= H) begin
            ny = H - 1;
            nvy = -vy;
        end

        // paddle bounce (only when moving toward the paddle)
        if (vx < 0 && nx <= 2 && ny >= $signed({1'b0, p1_y})
                           && ny < $signed({1'b0, p1_y}) + PADDLE_H) begin
            nvx = -vx;
            nx = 3;
        end else if (vx > 0 && nx >= W - 3 && ny >= $signed({1'b0, p2_y})
                           && ny < $signed({1'b0, p2_y}) + PADDLE_H) begin
            nvx = -vx;
            nx = W - 4;
        end

        // missed paddle => score
        if (nx < 0) begin
            scored = 1'b1;
            score_p1 = 1'b0;   // player 2 scores
        end else if (nx >= W) begin
            scored = 1'b1;
            score_p1 = 1'b1;   // player 1 scores
        end
    end

    // ---- sequential ----
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ball_x    <= W / 2;
            ball_y    <= H / 2;
            vx        <= 1;
            vy        <= 1;
            p1_y      <= H / 2 - PADDLE_H / 2;
            p2_y      <= H / 2 - PADDLE_H / 2;
            score1    <= 0;
            score2    <= 0;
            game_over <= 0;
            tick_cnt  <= 0;
        end else if (!game_over) begin
            // paddles: free-running, one pixel per clock while held
            if (p1_up   && p1_y > 0)             p1_y <= p1_y - 1;
            if (p1_down && p1_y < H - PADDLE_H)  p1_y <= p1_y + 1;
            if (p2_up   && p2_y > 0)             p2_y <= p2_y - 1;
            if (p2_down && p2_y < H - PADDLE_H)  p2_y <= p2_y + 1;

            if (move_tick) begin
                tick_cnt <= 0;
                if (scored) begin
                    // update score, serve ball toward the player who was scored on
                    if (score_p1) begin
                        score1 <= score1 + 1;
                        if (score1 + 1 >= WIN_SCORE) game_over <= 1;
                    end else begin
                        score2 <= score2 + 1;
                        if (score2 + 1 >= WIN_SCORE) game_over <= 1;
                    end
                    ball_x <= W / 2;
                    ball_y <= H / 2;
                    // serve toward the player who missed (loser receives)
                    vx     <= score_p1 ? 1 : -1;
                    vy     <= 1;
                end else begin
                    ball_x <= nx[9:0];
                    ball_y <= ny[9:0];
                    vx     <= nvx[9:0];
                    vy     <= nvy[9:0];
                end
            end else begin
                tick_cnt <= tick_cnt + 1;
            end
        end
    end

endmodule
