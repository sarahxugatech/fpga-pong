# FPGA Pong Game (Verilog, simulation-verified)

Pong game logic in Verilog — ball physics, paddle control, collision detection,
scoring, and win detection — verified with an Icarus Verilog testbench.
No FPGA board required; the design is written to be synthesizable.

## Files

- `pong.v` — game logic (parameterized field size, paddle height, win score)
- `pong_tb.v` — testbench: reset, paddle movement/clamping, ball motion,
  scoring on miss, wall bounce, game-over freeze

## Game rules

- Ball bounces off top/bottom walls and paddles
- Missing a paddle scores for the opponent; ball re-serves toward the scored-on side
- First to `WIN_SCORE` wins; logic freezes on `game_over`

## Module interface

```verilog
pong #(.W(64), .H(32), .PADDLE_H(6), .WIN_SCORE(5), .TICKS_PER_MOVE(10)) ...
  input  clk, rst,
  input  p1_up, p1_down, p2_up, p2_down,   // level-sensitive paddle controls
  output [9:0] ball_x, ball_y, p1_y, p2_y,
  output signed [9:0] vx, vy,
  output [3:0] score1, score2,
  output game_over
```

## Run it

```bash
# install: sudo apt-get install iverilog
iverilog -g2012 -o pong_tb pong.v pong_tb.v && vvp pong_tb
```

## Roadmap

- [ ] VGA timing module for real display output
- [ ] Single-player AI paddle
- [ ] Synthesize for a real FPGA board (iCE40 / Artix-7)
