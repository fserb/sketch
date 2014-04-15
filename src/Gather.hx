//@ ugl.bgcolor = 0xFFFFFF

/*
  - initial board example
  - more colors
*/

import vault.ugl.*;
import flash.geom.Rectangle;
import vault.EMath;
import vault.Vec2;
import vault.Ease;
import vault.ugl.PixelArt.C;

class Gather extends Game {
  public var COLORS = [ 0xff6819, 0xc0dc61, 0x1ebed8, 0xfec804, 0xe284cc ];

  var score: Float;
  var scoreDisplay: Text;
  var scroll: Float;
  var difficulty: Float;
  public var scoreColors: ScoreAnim;
  public var maxy: Float;
  static public function main() {
    // Game.debug = true;
    Game.baseColor = 0x000000;
    new Gather("Gather", "");
  }
  override public function final() {
    new Score(score, true);
    scoreColors.reset();
    Game.mouse.clear();
    Game.key.clear();
    Game.shake(1.0);
    acc = 0.0;
  }

  var acc = 0.0;
  override public function finalupdate() {
    acc += 500*Game.time;
    scroll += acc*Game.time;
    if (scroll >= 480) {
      Game.clear();
      makeTitle();
      state = TITLE;
    }
  }

  override public function end() {
    new Sound(30).explosion().cache("end game").play();
  }

  public function pos(x: Int, y: Int): Vec2 {
    return new Vec2(69 + x*38 + 19, scroll + 50 + y*38 + 19);
  }

  public var grid: Array<Array<Piece>>;

  override public function begin() {
    new Frame();
    scoreColors = new ScoreAnim();
    difficulty = 0.0;
    score = 0.0;
    scoreDisplay = new Text().color(0x222222).size(3).xy(240, 25);
    scroll = 0.0;
    grid = new Array<Array<Piece>>();
    for (x in 0...9) {
      grid.push(new Array<Piece>());
      for (y in 0...11) {
        grid[x].push(null);
      }
    }

    for (x in 0...9) {
      for (y in 0...11) {
        if (x == 4 && y == 5) {
          continue;
        }
        grid[x][y] = new Piece(x, y, Std.int(Math.random()*5));
      }
    }
    new Cursor(4, 5);
  }

  public function addScore(f: Float) {
    score += f;
    Game.shake(0.25);
    new Sound(12).coin().cache("score").play();
    new Text().size(1).color(0x000000).xy(245 + scoreDisplay.sprite.width/2.0, 25)
      .align(MIDDLE_LEFT).move(40, 0).duration(0.5).text("+" + Std.int(f));
  }

  override public function update() {
    var speed = Game.time*5*(1 + difficulty);
    if (maxy < 240) {
      speed *= 1 + 9*(240 - maxy)/70.0;
    }
    difficulty += 0.5*Game.time/60.0;

    scroll += speed;
    if (scroll > 0.0) {
      scroll -= 38;
      // move everyone down
      for (y in 0...11) {
        for (x in 0...9) {
          if (grid[x][y] != null) {
            grid[x][y].py += 1;
          }
        }
      }

      for (y in 0...10) {
        for (x in 0...9) {
          if (y != 11) {
            grid[x][10 - y] = grid[x][9 - y];
          }
        }
      }
      for (x in 0...9) {
        if (Math.random() < Math.min(0.05, difficulty/10.0)) {
          grid[x][0] = null;
          continue;
        }
        grid[x][0] = new Piece(x, 0, Std.int(Math.random()*5));
      }
      for (e in Game.get("Cursor")) {
        var c: Cursor = cast e;
        c.py += 1;
      }
    }
    maxy = 0.0;

    scoreDisplay.text("" + Std.int(score));
    new Score(score, false);
  }
}

class Piece extends Entity {
  public var px: Int;
  public var py: Int;
  public var targeted: Bool;
  var popping: Bool;

  static var layer = 10;
  public var color: Int;
  var eye: Vec2;
  public var size: Float;
  override public function begin() {
    px = args[0];
    py = args[1];
    color = args[2];
    targeted = false;
    popping = false;
    pos = Game.main.pos(px, py);
    size = 1.0;
    eye = new Vec2(Math.random()*480, Math.random()*480);
    draw();
  }

  public function target() {
    targeted = true;
    draw();
  }

  public function untarget() {
    targeted = false;
    draw();
  }

  function draw() {
    art.clear();
    var c = Game.main.COLORS[color];

    var s = 4;
    art.size(4, 9, 9).obj([c, 0x000000, 0xFFFFFF, 0x444444], "
    311111113
    100000001
    102202201
    102202201
    100000001
    100000001
    100000001
    100000001
    311111113
        ");

    var t = eye.distance(pos);
    t.normalize();
    t.mul(0.5);
    gfx.fill(0x000000).rect(Math.round(s*(2.5 + t.x)), Math.round(s*(2.5 + t.y)), s, s);
    gfx.fill(0x000000).rect(Math.round(s*(5.5 + t.x)), Math.round(s*(2.5 + t.y)), s, s);

    sprite.scaleX = sprite.scaleY = size;
  }

  public function pop() {
    Game.main.grid[px][py] = null;
    popping = true;
    targeted = false;
  }

  public function see(v: Vec2) {
    eye = v.copy();
    draw();
  }

  override public function update() {
    if (Math.random() < 1.0/(10*11*9)) {
      eye.x = Math.random()*480;
      eye.y = Math.random()*480;
      draw();
    }

    pos = Game.main.pos(px, py);
    if (pos.y > 484) {

      remove();
    }

    if (popping) {
      size = Math.max(0.0, size - Game.time/0.3);
      draw();
      if (size <= 0.0) {
        remove();
      }
    } else if (targeted) {
      eye = pos;
      var ns = Math.max(0.5, size - Game.time/0.3);
      if (ns != size) {
        size = ns;
        draw();
      }
    } else {
      var ns = Math.min(1.0, size + Game.time/0.3);
      if (ns != size) {
        size = ns;
        draw();
      }
    }
  }
}

class Cursor extends Entity {
  static var layer = 11;
  public var head: Bool;
  public var px: Int;
  public var py: Int;

  override public function begin() {
    px = args[0];
    py = args[1];
    pos = Game.main.pos(px, py);
    head = true;
    draw();
  }

  function draw() {
    var cols = head ? [ 0xFF6666, 0xFF9999 ] :
                      [ 0x666666, 0x999999 ];
    art.clear().size(4, 9, 9).obj( cols, "
100...001
0.......0
0.......0
.........
.........
.........
0.......0
0.......0
100...001
      ");
  }

  function check() {
    var counts = [ 0, 0, 0, 0, 0];
    for (e in Game.get("Cursor")) {
      var c: Cursor = cast e;
      var p = Game.main.grid[c.px][c.py];
      if (p == null) continue;
      counts[p.color] += 1;
    }

    Game.main.scoreColors.set(counts);

    var mv = 0;
    var cnt = 0;
    for (c in counts) {
      mv = EMath.max(mv, c);
      if (c > 0) cnt += 1;
    }
    if (cnt <= 1) return;
    if (mv <= 1) return;
    for (c in counts) {
      if (c > 0 && c < mv) return;
    }

    // passed
    for (e in Game.get("Cursor")) {
      var c: Cursor = cast e;
      if (!c.head) {
        c.pop();
      }
      var p = Game.main.grid[c.px][c.py];
      if (p == null) continue;
      p.pop();
    }
    new Sound(25).explosion().cache("gather").play();
    Game.main.scoreColors.go();
  }

  public function pop() {
    remove();
  }

  override public function update() {
    pos = Game.main.pos(px, py);
    Game.main.maxy = Math.max(Game.main.maxy, pos.y);

    if (Game.key.b1_pressed) {
      if (Game.main.grid[px][py] != null) {
        Game.main.grid[px][py].untarget();
        remove();
      } else {
        head = true;
        Game.main.scoreColors.reset();
        draw();
      }
    }

    if (pos.y >= 450) {
      return Game.endGame();
    }

    if (!head) return;

    if (px > 0 && Game.main.grid[px-1][py] != null) Game.main.grid[px-1][py].see(pos);
    if (px < 8 && Game.main.grid[px+1][py] != null) Game.main.grid[px+1][py].see(pos);
    if (py > 0 && Game.main.grid[px][py-1] != null) Game.main.grid[px][py-1].see(pos);
    if (py < 10 && Game.main.grid[px][py+1] != null) Game.main.grid[px][py+1].see(pos);

    // try to move
    var tx = px;
    var ty = py;
    if (Game.key.up_pressed) ty -= 1;
    if (Game.key.down_pressed) ty += 1;
    if (Game.key.left_pressed) tx -= 1;
    if (Game.key.right_pressed) tx += 1;
    // not allowed outside
    if (tx < 0 || tx >= 9 || ty < 0 || ty >= 11) {
      tx = px; ty = py;
    } else if (Game.main.grid[tx][ty] == null) {
      if (Game.main.grid[px][py] == null) {
        px = tx; py = ty;
        return;
      }
      tx = px; ty = py;
    } else if (Game.main.grid[tx][ty].targeted) {
      tx = px; ty = py;
    }

    if (tx != px || ty != py) {
      new Sound(12).jump().cache("move").play();

      new Cursor(tx, ty);
      Game.main.grid[tx][ty].target();
      head = false;
      draw();
      check();
    }
  }
}

class ScoreAnim extends Entity {
  static var layer = 101;
  var moving = false;
  var values: Array<Int> = null;
  var score = 0.0;

  public function reset() {
    set([0,0,0,0,0]);
  }

  public function set(v: Array<Int>) {
    values = v;
    var g = gfx.cache(v[0] + v[1]*10 + v[2]*100 + v[3]*1000 + v[4]*10000);
    var l = 0;
    var order = [0,1,2,3,4];
    order.sort(function(a, b) {
      if (v[a] < v[b]) return 1;
      if (v[a] > v[b]) return -1;
      return 0;
    });

    for (i in order) {
      var c = v[i];
      if (c == 0) continue;
      g.fill(Game.main.COLORS[i]);
      for (j in 0...c) {
        g.rect(j*8, l*8, 7, 7);
      }
      l += 1;
    }
  }

  public function go() {
    Game.main.scoreColors = new ScoreAnim();
    moving = true;
    ticks = 0.0;

    var cnt = 0;
    var pieces = 0;
    for (v in values) {
      if (v != 0) {
        cnt += 1;
        pieces = v;
      }
    }

    score = cnt*pieces*(pieces - 1)*(cnt - 1)*(1 + Game.main.difficulty);
  }

  override public function begin() {
    alignment = MIDDLELEFT;
    pos.x = 50;
    pos.y = 25;
  }

  override public function update() {
    if (!moving) return;

    var t = ticks/0.3;
    pos.x = 50 + 190*Ease.quadIn(t);
    sprite.alpha = 1.0 - Ease.quadIn(t);
    if (t > 1.0) {
      Game.main.addScore(score);
      remove();
    }
  }
}

class Frame extends Entity {
  static var layer = 100;
  override public function begin() {
    alignment = TOPLEFT;
    pos.x = pos.y = 0;
    gfx.fill(0xFFFFFF)
      .rect(0, 468, 480, 12)
      .rect(0, 0, 480, 50)
      .fill(null).line(1, 0x000000)
      .mt(50, 50).lt(420, 50)
      .mt(50, 468).lt(420, 468);
    var g = gfx.gfx();
    g.lineStyle(1.0, 0x000000, 0.25);
    g.moveTo(50, 51); g.lineTo(420, 51);
    g.moveTo(50, 467); g.lineTo(420, 467);
    g.lineStyle(1.0, 0x000000, 0.12);
    g.moveTo(50, 52); g.lineTo(420, 52);
    g.moveTo(50, 466); g.lineTo(420, 466);
  }
}

