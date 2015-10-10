//@ ugl.bgcolor = 0x303030

import vault.ugl.*;
import vault.EMath;
import vault.Vec2;
import vault.Grid;
import vault.Act;
import vault.Ease;

class C {
  static public var black:UInt = 0x606060;
  static public var p1: UInt = 0x1ebed8;
  static public var p2: UInt = 0xff6819;
  static public var white:UInt = 0xFAFAFA;
  static public var bg:UInt = 0xFAFAFA;
}

class Wall extends Micro {
  public var level: Level;
  var player: Player;
  static public function main() {
    new Wall("Wall", "");
  }

  override public function begin() {
    level = new Level();
    player = new Player(level.grid);
  }

  override public function update() {
    var cam = player.pos.copy();
    cam.x -= 240;
    cam.y -= 240;


    var lev = level.pos.distance(cam);
    if (lev.x > 0) { cam.x += lev.x; }
    if (lev.y > 0) { cam.y += lev.y; }
    if (24*40 + lev.x < 480) { cam.x -= 480 - (24*40 + lev.x); }
    if (24*40 + lev.y < 480) { cam.y -= 480 - (24*40 + lev.y); }

    if (player.vel.y != 0) cam.y = 0;
    cam.clamp(200*Game.time);

    player.pos.sub(cam);
    level.pos.sub(cam);
  }
}

class Level extends Entity {
  public var grid: Grid;
  static var layer = 10;
  override public function begin() {
    alignment = TOPLEFT;
    pos.x = -480;
    pos.y = -480;

    var s = new flash.display.Sprite();
    grid = new Grid(24, 24, 40, s);
    grid.offset = pos.copy();
    Game.sprite.addChild(s);
    grid.load([ {block:true, type:1}, {block:false, type:2} ], "
000000000000000000000000
0......................0
0......................0
0......................0
000.................0000
0......................0
0........0000..........0
0......................0
0......................0
0.....1.............0000
0......................0
0..............1.......0
0......................0
0....0.0.0.............0
0......................0
0.........0000.........0
0......................0
00.....................0
0..............11111...0
0......................0
0........000...........0
0.....000.........0....0
0.................0....0
000000000000000000000000
");
    draw();
  }

  override public function update() {
    grid.updateOffset(pos);
  }

  public function draw() {
    gfx.clear();
    gfx.fill(C.white).rect(0, 0, grid.width*grid.tilesize, grid.height*grid.tilesize);
    for (x in 0...grid.width) {
      for (y in 0...grid.height) {
        if (grid.map[x][y] == null) continue;
        if (grid.map[x][y].type == 1) {
          gfx.fill(C.black).rect(x*grid.tilesize, y*grid.tilesize,
                                 grid.tilesize, grid.tilesize);
        }
        if (grid.map[x][y].type == 2) {
          gfx.fill(0xCCCCCC).rect(x*grid.tilesize, y*grid.tilesize,
                                 grid.tilesize, grid.tilesize);
        }
      }
    }
  }
}

class Player extends Entity {
  static var layer = 20;

  public var state = 0;
  var dt = 0.0;
  var grid: Grid;
  var facingleft: Bool = true;
  var bfall = 0.0;
  public var locked = false;

  override public function begin() {
    grid = args[0];
    pos.x = 0;
    pos.y = 0;
    grid.add(this, pos, -8.5, -8.5, 17, 19);
    draw();
    // addHitBox(Rect(0,0,3*5,3*7));
  }

  function draw() {
    var big = vel.y < -150;
    art.clear().size(3, 7, big ? 10 : 7).obj([C.p1],
      (facingleft ? "00000.." : "..00000") +
      (facingleft ? "000000." : ".000000") +
"
.0.0.0.
.00000.
.00000.
..000.."
+ (big ? "..000....000....000.." : "") +
".00000.");
  }

  override public function update() {
    if (locked) {
      vel.x = vel.y = 0;
      return;
    }
    var touch = grid.get(this).touch;
    var collide = grid.get(this).collide;
    acc.x = -vel.x/Game.time;

    if (touch & 1 == 1) {
      vel.y = 0;
    }

    if (touch & 4 == 4) {
      vel.y = 0;
      bfall = 0.1;
    } else {
      acc.y = 1000;
      if (touch == 2 || touch == 8) {
        if (Game.key.up_pressed) {
          vel.y = -400;
          vel.x = vel.x > 0 ? -500 : 500;
          acc.x = 0;
        }
      } else {
        if (!Game.key.up) {
          vel.y = Math.max(vel.y, -150);
        }
      }
    }

    bfall = Math.max(0.0, bfall - Game.time);
    if (touch & 4 == 4 || bfall > 0.0) {
      if (Game.key.up_pressed) {
        vel.y = -400;
      }
    }

    if (Game.key.left) {
      acc.x += -10000;
      facingleft = true;
    }
    if (Game.key.right) {
      acc.x += 10000;
      facingleft = false;
    }
  }

  override public function postUpdate() {
    if (locked) return;
    pos = grid.update(this, pos);
    draw();
    var r = grid.get(this).rect;
    var bot = pos.y + r.x + r.h - 1;
    for (x in 0...grid.width) {
      for (y in 0...grid.height) {
        if (grid.map[x][y] == null) continue;
        if (grid.map[x][y].type == 2) {
          grid.map[x][y].block = (bot <= y*grid.tilesize + grid.offset.y);
        }
      }
    }
  }
}
