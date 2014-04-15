//@ ugl.bgcolor = 0xFFFFFF

/*
  - grid movement
  - pieces look randomly and at the cursor when close
*/

import vault.ugl.*;
import flash.geom.Rectangle;
import vault.EMath;
import vault.Vec2;
import vault.ugl.PixelArt.C;

class Gather extends Game {

  static public function main() {
    Game.debug = true;
    new Gather("Gather", "");
  }

  public function pos(x: Int, y: Int): Vec2 {
    return new Vec2(69 + x*38 + 19, 50 + y*38 + 19);
  }

  public var grid: Array<Array<Piece>>;

  override public function begin() {
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
}

class Piece extends Entity {
  var px: Int;
  var py: Int;
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
  var px: Int;
  var py: Int;

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

    if (Game.key.b1_pressed) {
      if (Game.main.grid[px][py] != null) {
        Game.main.grid[px][py].untarget();
        remove();
      } else {
        head = true;
        draw();
      }
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
    }
    if (Game.main.grid[tx][ty] == null ||
        Game.main.grid[tx][ty].targeted) {
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

