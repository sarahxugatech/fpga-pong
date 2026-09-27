"""Functional model of pong.v — mirrors the Verilog logic cycle-by-cycle.

Validates the GAME DESIGN (ball physics, collision, scoring). The Verilog
implementation (pong.v) is the synthesizable deliverable; run it under
Icarus Verilog for the true HDL simulation:
    iverilog -g2012 -o pong_tb pong.v pong_tb.v && vvp pong_tb
"""

from dataclasses import dataclass


@dataclass
class Pong:
    W: int = 64
    H: int = 32
    PADDLE_H: int = 6
    WIN_SCORE: int = 3
    TICKS_PER_MOVE: int = 2

    def __post_init__(self):
        self.reset()

    def reset(self):
        self.ball_x, self.ball_y = self.W // 2, self.H // 2
        self.vx, self.vy = 1, 1
        self.p1_y = self.p2_y = self.H // 2 - self.PADDLE_H // 2
        self.score1 = self.score2 = 0
        self.game_over = False
        self.tick_cnt = 0

    def clock(self, p1_up=False, p1_down=False, p2_up=False, p2_down=False):
        if self.game_over:
            return
        if p1_up and self.p1_y > 0:
            self.p1_y -= 1
        if p1_down and self.p1_y < self.H - self.PADDLE_H:
            self.p1_y += 1
        if p2_up and self.p2_y > 0:
            self.p2_y -= 1
        if p2_down and self.p2_y < self.H - self.PADDLE_H:
            self.p2_y += 1
        self.tick_cnt += 1
        if self.tick_cnt >= self.TICKS_PER_MOVE:
            self.tick_cnt = 0
            self._move_ball()

    def _serve(self, loser_is_p1: bool):
        self.ball_x, self.ball_y = self.W // 2, self.H // 2
        self.vx = -1 if loser_is_p1 else 1  # loser receives
        self.vy = 1

    def _move_ball(self):
        nx, ny = self.ball_x + self.vx, self.ball_y + self.vy
        nvx, nvy = self.vx, self.vy
        if ny < 0:
            ny, nvy = 0, -self.vy
        elif ny >= self.H:
            ny, nvy = self.H - 1, -self.vy
        if self.vx < 0 and nx <= 2 and self.p1_y <= ny < self.p1_y + self.PADDLE_H:
            nvx, nx = -self.vx, 3
        elif self.vx > 0 and nx >= self.W - 3 and self.p2_y <= ny < self.p2_y + self.PADDLE_H:
            nvx, nx = -self.vx, self.W - 4
        if nx < 0:
            self.score2 += 1
            if self.score2 >= self.WIN_SCORE:
                self.game_over = True
            self._serve(loser_is_p1=True)
        elif nx >= self.W:
            self.score1 += 1
            if self.score1 >= self.WIN_SCORE:
                self.game_over = True
            self._serve(loser_is_p1=False)
        else:
            self.ball_x, self.ball_y, self.vx, self.vy = nx, ny, nvx, nvy


def run_checks():
    fails = 0

    def check(cond, msg):
        nonlocal fails
        print(("PASS: " if cond else "FAIL: ") + msg)
        if not cond:
            fails += 1

    g = Pong()
    check((g.ball_x, g.ball_y) == (32, 16), "reset centers ball")
    check((g.p1_y, g.p2_y) == (13, 13), "reset centers paddles")

    for _ in range(20):
        g.clock(p1_up=True)
    check(g.p1_y < 13, "p1 paddle moves up")
    for _ in range(200):
        g.clock(p1_up=True)
    check(g.p1_y == 0, "p1 paddle clamps at top edge")

    g = Pong()
    bx0 = g.ball_x
    for _ in range(10):
        g.clock()
    check(g.ball_x != bx0, "ball moves over time")

    # force a miss
    g.p1_y = 26
    g.ball_x, g.ball_y, g.vx, g.vy = 4, 2, -1, 0
    while g.score2 == 0:
        g.clock()
    check(g.score2 == 1, "player 2 scores when p1 misses")
    check(g.ball_x == 32 and g.vx == -1, "ball re-served to center, toward p1 (loser receives)")

    # wall bounce
    g.ball_x, g.ball_y, g.vx, g.vy = 32, 1, 0, -1
    for _ in range(10):
        g.clock()
    check(g.vy == 1, "ball bounces off top wall (vy flips)")

    # paddle bounce: ball moving left into p1 paddle
    g = Pong()
    g.ball_x, g.ball_y, g.vx, g.vy = 5, 14, -1, 0
    for _ in range(10):
        g.clock()
    check(g.vx == 1, "ball bounces off p1 paddle (vx flips)")

    # game over
    g = Pong()
    g.score1 = 2
    g.ball_x, g.ball_y, g.vx, g.vy = 60, 2, 1, 0
    g.p2_y = 26
    for _ in range(20):
        g.clock()
    check(g.score1 == 3, "player 1 reaches winning score")
    check(g.game_over, "game_over asserted at WIN_SCORE")
    bx0 = g.ball_x
    for _ in range(20):
        g.clock()
    check(g.ball_x == bx0, "ball frozen after game over")

    print("ALL TESTS PASSED" if fails == 0 else f"{fails} TEST(S) FAILED")


if __name__ == "__main__":
    run_checks()
