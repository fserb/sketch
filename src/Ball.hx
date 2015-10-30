//@ ugl.bgcolor = 0x303030

import vault.ugl.*;
import vault.EMath;
import vault.geom.Vec2;
import vault.Grid;
import vault.Act;
import vault.Ease;
import vault.Sight;
import vault.PostProcess;

class C {
  static public var black:UInt = 0x606060;
  static public var p1: UInt = 0x1ebed8;
  static public var p2: UInt = 0xff6819;
  static public var white:UInt = 0xFAFAFA;
  static public var bg:UInt = 0xFAFAFA;
}

class Ball extends Micro {
  public var grid: Grid;
  var wall: Wall;
  var player: Player;
  var compass: Compass;
  var sighter: Sighter;
  static public function main() {
    new Ball("Ball", "");
  }

  override public function begin() {
    var s = new flash.display.Sprite();
    grid = new Grid(24, 24, 20, s);
    Game.sprite.addChild(s);
    grid.load([ {block:true, type:1}, {block:false, type:2} ], "
000000000000000000000000
0......................0
0......................0
0......................0
000.................0000
0......................0
0........0000...1......0
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
    player = new Player(grid);
    sighter = new Sighter(grid, player);
    wall = new Wall(grid);
    // compass = new Compass();
  }

  function rotate(sz: Int = 1) {
    var cangle = compass.angle;
    var initialangle: Float;

    Act.obj(this)
    .tween(function(z) {
      compass.angle = cangle - sz*Math.PI/2*z;
    }, 0.4, Ease.cubicIn).delay(0.5).then(function() {
      player.locked = true;
      initialangle = player.pos.distance(new Vec2(240,240)).angle;
      cangle = compass.angle;
    })
    .tween(function(z) {
      wall.angle = sz*Math.PI/2*z;
      compass.angle = cangle + sz*Math.PI/2*z;
      var d = player.pos.distance(new Vec2(240, 240));
      d.angle = initialangle + sz*Math.PI/2*z;
      player.pos.x = 240 + d.x;
      player.pos.y = 240 + d.y;

    }, Math.abs(0.6*sz), Ease.cubicIn).then(function() {
      trace(sz, (4 + sz)%4);
      for (i in 0...(4 + sz)%4) {
        var oldmap = grid.map;
        grid.map = [];
        for (x in 0...grid.width) {
          var c = new Array<Tile>();
          for (y in 0...grid.height) {
            c.push(oldmap[y][grid.width-x-1]);
          }
          grid.map.push(c);
        }
      }
      wall.draw();
      wall.angle = 0;
      player.locked = false;
      grid.get(player).pos = player.pos.copy();
    });
  }

  override public function update() {
    grid.debug();
    if (Game.key.b1_pressed) {
      rotate([1, -1, 2][Std.int(3*Math.random())]);
    }
  }
}

class Sighter extends Entity {
  static var layer = 19;
  var grid: Grid;
  var player: Player;
  var sight: Sight;
  override public function begin() {
    pos.x = pos.y = 0;
    alignment = TOPLEFT;
    grid = args[0];
    player = args[1];
    sight = grid.getSight();
  }


  override public function update() {
    gfx.clear();

    // gfx.line(1, 0x00FF00, 1.0);
    // for (w in sight.walls) {
    //   gfx.mt(w.a.x, w.a.y);
    //   gfx.lt(w.b.x, w.b.y);
    // }
    // gfx.line(null);

    for (t in sight.castLOS(player.pos)) {
      gfx.fill(0x1ebed8, 0.2);
      gfx.mt(t.a.x, t.a.y);
      gfx.lt(t.b.x, t.b.y);
      gfx.lt(t.c.x, t.c.y);
    }
    // for (a in 0...10) {
    //   var p = new Vec2(7, 0);
    //   p.angle = 2*Math.PI*a/10;
    //   p.add(player.pos);
    //   for (t in sight.castLOS(p)) {
    //     gfx.fill(0xFF0000, 0.1);
    //     gfx.mt(t.a.x, t.a.y);
    //     gfx.lt(t.b.x, t.b.y);
    //     gfx.lt(t.c.x, t.c.y);
    //   }
    // }
  }
}

class Player extends Entity {
  static var layer = 20;

  var state = 0;
  var dt = 0.0;
  var grid: Grid;
  var facingleft: Bool = true;
  var bfall = 0.0;
  public var locked = false;

  override public function begin() {
    grid = args[0];
    pos.x = 40;
    pos.y = 480-35;
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
          grid.map[x][y].block = (bot <= y*grid.tilesize);
        }
      }
    }
  }
}

class Wall extends Entity {
  var grid: Grid;
  static var layer = 10;
  override public function begin() {
    grid = args[0];
    alignment = TOPLEFT;
    draw();
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

class Compass extends Entity {
  static var layer = 11;
  override public function begin() {
    pos.x = pos.y = 240;
    gfx.line(2, 0x888888).mt(6, 0).lt(6, 12);
    gfx.mt(6,0).lt(0, 6);
    gfx.mt(6,0).lt(12, 6);
  }
}
