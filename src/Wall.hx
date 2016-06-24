//@ ugl.bgcolor = 0x303030

import vault.Grid;
import vault.Sight;

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
  var sighter: Sighter;
  static public function main() {
    new Wall("Wall", "");
  }

  override public function begin() {
    level = new Level();
    player = new Player(level.grid);
    sighter = new Sighter(level.grid, player, level);
  }

  override public function update() {
    var cam = player.pos.copy();

    cam.x -= 240;
    cam.y -= 240;
    cam.clamp(200*Game.time);

    var l = level.pos.distance(cam);
    if (l.x > 0) {
      cam.x += l.x;
    }
    if (l.y > 0) {
      cam.y += l.y;
    }
    if (l.y < 0) {
      cam.y += l.y;
    }
    // if (l.x <= -(48*20-480)) {
    //   cam.x <= -(48*20-480)-l.x;
    // }
    // if (l.y < 0) {
    //   cam.y -= l.y;
    // }

    level.pos.sub(cam);
    player.pos.sub(cam);
    sighter.pos.sub(cam);
  }
}

class Level extends Entity {
  public var grid: Grid;
  static var layer = 10;
  override public function begin() {
    alignment = TOPLEFT;
    pos.x = -240;
    pos.y = -240;

    var s = new flash.display.Sprite();
    grid = new Grid(48, 24, 20, s);
    grid.offset = pos.copy();
    Game.sprite.addChild(s);
    grid.load([ {block:true, type:1} ], "
000000000000000000000000000000000000000000000000
0..............................................0
0..............................................0
0..............................................0
000.........................................0000
0..............................................0
0........0000..................................0
0..............................................0
0..............................................0
0.....0.....................................0000
0..............................................0
0..............0...............................0
0..............................................0
0....0.0.0.....................................0
0..............................................0
0.........0000.................................0
0..............................................0
00.............................................0
0..............00000...........................0
0..............................................0
0........000...................................0
0.....000.........0............................0
0.................0............................0
000000000000000000000000000000000000000000000000
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


class Sighter extends Entity {
  static var layer = 19;
  var grid: Grid;
  var player: Player;
  var sight: Sight;
  var level: Level;
  override public function begin() {
    pos.x = pos.y = -240;
    alignment = TOPLEFT;
    grid = args[0];
    player = args[1];
    level = args[2];
    sight = grid.getSight();
  }


  override public function update() {
    gfx.clear();

    var p = player.pos.copy();
    p.sub(level.pos);

    for (t in sight.castLOS(p)) {
      gfx.fill(0x1ebed8, 0.2);
      gfx.mt(t.a.x, t.a.y);
      gfx.lt(t.b.x, t.b.y);
      gfx.lt(t.c.x, t.c.y);
    }
  }
}


class Player extends Entity {
  static var layer = 20;

  var grid: Grid;
  var facingleft: Bool = true;
  var bfall = 0.0;
  public var locked = false;

  override public function begin() {
    grid = args[0];
    pos.x = 0;
    pos.y = 0;
    grid.add(this, pos, -8, -8, 14, 17);
    draw();
    // addHitBox(Rect(0,0,3*5,3*7));
  }

  function draw() {
    art.clear().size(3, 7, 7).obj([C.p1],
      (facingleft ? "00000.." : "..00000") +
      (facingleft ? "000000." : ".000000") +
".0.0.0.
.00000.
.00000.
..000..
.00000.");
  }

  override public function update() {
    acc.x = -vel.x/Game.time;
    acc.y = -vel.y/Game.time;

    if (Game.key.up) {
      acc.y += -10000;
      facingleft = true;
    }
    if (Game.key.down) {
      acc.y += 10000;
      facingleft = true;
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
    pos = grid.update(this, pos);
    draw();
  }
}
