//@ ugl.bgcolor = 0xFFFFFF

/*
  - pieces look randomly and at the cursor when close
*/

import vault.ugl.*;
import flash.geom.Rectangle;
import vault.EMath;
import vault.Vec2;
import vault.ugl.PixelArt.C;

class Gather extends Game {
  var scroll: Float;
  public var maxy: Float;
  static public function main() {
    Game.debug = true;
    Game.baseColor = 0x000000;
    new Gather("Gather", "");
  }
  override public function final() {
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
    return;
    for (e in Game.get("Cursor")) {
      var c: Cursor = cast e;
      if (c.py < 11 && Game.main.grid[c.px][c.py] != null) {
        Game.main.grid[c.px][c.py].untarget();
      }
      c.remove();
    }
  }

  public function pos(x: Int, y: Int): Vec2 {
    return new Vec2(69 + x*38 + 19, scroll + 50 + y*38 + 19);
  }

  public var grid: Array<Array<Piece>>;

  override public function begin() {
    new Frame();
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

  override public function update() {
    var speed = Game.time*10;
    if (maxy < 240) {
      speed *= 1 + 5*(240 - maxy)/70.0;
    }

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
        grid[x][0] = new Piece(x, 0, Std.int(Math.random()*5));
      }
      for (e in Game.get("Cursor")) {
        var c: Cursor = cast e;
        c.py += 1;
      }
    }
    maxy = 0.0;
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
    var c = switch (color) {
      case 0: 0xff6819;
      case 1: 0xc0dc61;
      case 2: 0x1ebed8;
      case 3: 0xfec804;
      case 4: 0xe284cc;
      default: 0xFFFFFF;
    };

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

  override public function update() {
    pos = Game.main.pos(px, py);
    if (pos.y >= 480) {
      remove();
    }

    if (popping) {
      size = Math.max(0.0, size - Game.time/0.3);
      draw();
      if (size <= 0.0) {
        remove();
      }
    } else if (targeted) {
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
    var cols = head ? [ 0xFF6666, 0xFF9999, 0xFFFFFF ] :
                      [ 0x666666, 0x999999, 0xFFFFFF ];
    art.clear().size(4, 9, 9).obj( cols, "
100222001
0.......0
0.......0
2.......2
2.......2
2.......2
0.......0
0.......0
100222001
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

    var mv = 0;
    var cnt = 0;
    for (c in counts) {
      mv = EMath.max(mv, c);
      if (c > 0) cnt += 1;
    }
    trace(counts);
    if (cnt <= 1) return;
    if (mv <= 1) return;
    for (c in counts) {
      if (c > 0 && c < mv) return;
    }

    // passed
    Game.shake(0.3);
    for (e in Game.get("Cursor")) {
      var c: Cursor = cast e;
      if (!c.head) {
        c.pop();
      }
      var p = Game.main.grid[c.px][c.py];
      if (p == null) continue;
      p.pop();
    }
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
        draw();
      }
    }

    if (pos.y >= 450) {
      return Game.endGame();
    }

    if (!head) return;
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
      new Cursor(tx, ty);
      Game.main.grid[tx][ty].target();
      head = false;
      draw();
      check();
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
      .fill(null).line(1, 0xAAAAAA)
      .mt(50, 50).lt(420, 50)
      .mt(50, 468).lt(420, 468);
  }
}
