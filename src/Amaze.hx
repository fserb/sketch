//@ ugl.bgcolor = 0x3dbf86

import vault.ugl.*;
import vault.EMath;
import vault.Vec2;

class Amaze extends Micro {
  static public function main() {
    new Amaze("Amaze", "maze + jump + key");
  }

  public var maze: Maze;
  public var player: Player;
  public var gate: Gate;
  public var level: Int = 0;

  override public function end() {
    player.remove();
    player = null;
  }

  override public function begin() {
    level = 0;
    next();
  }

  override public function final() {
    new Final();
  }

  public function buildNext() {
    Game.clear();
    level++;
    Game.totalTime = 0;
    maze = new Maze();
  }

  public function next() {
    if (level == 0) {
      buildNext();
    } else {
      player.remove();
      player = null;
      new Transition();
    }
  }
}

class Transition extends Entity {
  static var layer = 20;
  var t = 0.0;
  var txt: Text = null;
  var f = 0.0;
  override public function begin() {
    pos.x = Game.scene.gate.pos.x;
    pos.y = Game.scene.gate.pos.y;
  }
  override public function update() {
    t += Game.time/0.5;
    var g = sprite.graphics;

    if (t >= 0 && t <= 1.0) {
      g.clear();
      g.beginFill(0x444444);
      g.drawRect(0, 0, 480*2*t, 480*2*t);
    } else if (f == 0.0) {
      pos.x = pos.y = 240;
      if (txt == null) {
        txt = new Text().xy(240, 240).size(3).color(0xFFFFFFFF).text("Level " + (Game.scene.level + 1));
      }
      if (Game.key.any_pressed) {
        txt.remove();
        f += Game.time;
      }
    } else {
      f += Game.time/0.5;
      g.clear();
      g.beginFill(0x444444);
      g.drawRect(0, 0, 480, 480);
      g.beginFill(0x3dbf86);
      g.drawRect(240 - 240*f, 240 - 240*f, 480*f, 480*f);
      if (f >= 1.0) {
        Game.scene.buildNext();
      }
    }
  }
}

class Maze extends Entity {
  static var layer = 1;
  var map: Array<Array<Int>>;

  override public function begin() {
    alignment = TOPLEFT;
    pos.x = pos.y = 0;

    map = new Array<Array<Int>>();
    for (x in 0...15) {
      map.push(new Array<Int>());
      for (y in 0...15) {
        map[x].push(15);
      }
    }

    generate();
    draw();

    Game.scene.player = new Player();
    Game.scene.gate = new Gate();
    var key = new Key();
    var p0 = Std.int(Math.random()*15*15);
    var p1 = 15*15 - 1 - p0;
    setpos(Game.scene.gate, p0);
    setpos(key, p1);

    for (i in 0...Game.scene.level) {
      new Bot();
    }
  }

  function setpos(e: Entity, p: Int) {
    var px = p%15;
    var py = Std.int(p/15);
    e.pos.x = px*32 + 17;
    e.pos.y = py*32 + 17;
  }

  function draw() {
    var a = art.size(4).color(0xEEEEEE);
    var bs = 16/4;
    for (x in 0...15) {
      for (y in 0...15) {
        var m = map[x][y];
        var c = new Vec2((x + 0.5)*bs*2, (y + 0.5)*bs*2);
        if (m & 1 == 1) { a.hline(c.x - bs, c.x + bs, c.y - bs); }
        if (m & 2 == 2) { a.vline(c.x + bs, c.y - bs, c.y + bs); }
        if (m & 4 == 4) { a.hline(c.x - bs, c.x + bs, c.y + bs); }
        if (m & 8 == 8) { a.vline(c.x - bs, c.y - bs, c.y + bs); }
      }
    }
    a.lrect(0, 0, 480/4 - 1, 480/4 - 1);
  }

  function generate() {
    var border = new List<Int>();
    var setm = function(p, v) { map[p%15][Std.int(p/15)] = v; };
    var andm = function(p, v) { map[p%15][Std.int(p/15)] &= v; };
    var getm = function(p) { return map[p%15][Std.int(p/15)]; };
    var addneigh = function(p) {
      var x = p%15;
      var y = Std.int(p/15);
      if (x > 0 && getm(p-1) == 15) border.add(p-1);
      if (x < 14 && getm(p+1) == 15) border.add(p+1);
      if (y > 0 && getm(p-15) == 15) border.add(p-15);
      if (y < 14 && getm(p+15) == 15) border.add(p+15);
    };
    var v = 7 + 15*7;
    setm(v, 0);
    addneigh(v);

    while (!border.isEmpty()) {
      var sel = -1;
      var p = 0;
      for (i in border) {
        p += 1;
        if (Math.random() > 1/p) continue;
        sel = i;
      }
      border.remove(sel);

      if (getm(sel) != 15) continue;
      addneigh(sel);

      var x = sel%15;
      var y = Std.int(sel/15);
      var poss = new Array<Void -> Void>();
      if (y > 0 && getm(sel-15) != 15)  poss.push(function() { andm(sel, 14); andm(sel - 15, 11); }); else poss.push(null);
      if (x < 14 && getm(sel+1) != 15)  poss.push(function() { andm(sel, 13); andm(sel + 1, 7); }); else poss.push(null);
      if (y < 14 && getm(sel+15) != 15) poss.push(function() { andm(sel, 11); andm(sel + 15, 14); }); else poss.push(null);
      if (x > 0 && getm(sel-1) != 15) poss.push(function() { andm(sel, 7); andm(sel - 1, 13); }); else poss.push(null);

      var angle = new Vec2(x - 7.5, y - 7.5).angle;
      var order: Array<Int> = [];
      if ((angle >= 0 && angle < Math.PI/4) || (angle >= 7*Math.PI/4)) {
        order = [ 2, 0, 1, 3 ];
      } else if (angle >= Math.PI/4 && angle < 3*Math.PI/4) {
        order = [ 3, 1, 2, 0];
      } else if (angle >= 3*Math.PI/4 && angle < 5*Math.PI/4) {
        order = [ 0, 2, 3, 1 ];
      } else if (angle >= 5*Math.PI/4 && angle < 7*Math.PI/4) {
        order = [ 1, 3, 0, 2];
      } else {
        setm(sel, 0); continue;
      }

      for (o in order) {
        if (poss[o] != null) {
          poss[o]();
          break;
        }
      }

    }

    var sel = v;
    setm(v, 15);
    var x = sel%15;
    var y = Std.int(sel/15);
    if (x > 0 && getm(sel-1) != 15) { andm(sel, 7); andm(sel - 1, 13); }
    if (x < 14 && getm(sel+1) != 15)  { andm(sel, 13); andm(sel + 1, 7); }
    if (y > 0 && getm(sel-15) != 15)  { andm(sel, 14); andm(sel - 15, 11); }
    if (y < 14 && getm(sel+15) != 15) { andm(sel, 11); andm(sel + 15, 14); }
  }
}

class Player extends Entity {
  static var layer = 4;

  public var mx: Int;
  public var my: Int;
  public var tx: Int;
  public var ty: Int;
  var facing: Int;
  var cooldown: Float;
  public var leaving = -1.0;
  var jumpsnd: Sound;

  override public function begin() {
    mx = 7;
    my = 7;
    tx = 7;
    ty = 7;
    pos = new Vec2(mx*32 + 17, my*32 + 17);
    facing = 0;
    cooldown = 0.0;
    addHitBox(Rect(0, 0, 16, 16));
    jumpsnd = new Sound("player jump").jump(4);
  }

  public function door() {
    if (leaving < 0) {
      leaving = 1.0;
    }
  }

  function moveTo(d: Int) {
    facing = d;
    angle = d == 1 ? 0: d == 2 ? Math.PI/2 : d == 4 ? Math.PI : 3*Math.PI/2;

    if (Game.scene.maze.map[mx][my] & d == d) return;
    var dx = Math.abs(pos.x - (tx*32 + 17))/32;
    var dy = Math.abs(pos.y - (ty*32 + 17))/32;
    switch(d) {
      case 1: if (my > 0 && dx < 0.1) ty = my - 1;
      case 2: if (mx < 14 && dy < 0.1) tx = mx + 1;
      case 4: if (my < 14 && dx < 0.1) ty = my + 1;
      case 8: if (mx > 0 && dy < 0.1) tx = mx - 1;
    }
  }

  function jump() {
    if (cooldown > 0) return;
    if (Game.scene.maze.map[mx][my] & facing == 0) return;
    var dx = Math.abs(pos.x - (tx*32 + 17))/32;
    var dy = Math.abs(pos.y - (ty*32 + 17))/32;
    var jumped = false;
    switch(facing) {
      case 1: if (my > 0 && dx < 0.1) { ty = my - 1; jumped = true; }
      case 2: if (mx < 14 && dy < 0.1) { tx = mx + 1; jumped = true; }
      case 4: if (my < 14 && dx < 0.1) { ty = my + 1; jumped = true; }
      case 8: if (mx > 0 && dy < 0.1) { tx = mx - 1; jumped = true; }
    }
    if (jumped) {
      cooldown = 1.0;
      jumpsnd.play();
    }
  }

  override public function update() {
    mx = Math.round((pos.x - 17)/32);
    my = Math.round((pos.y - 17)/32);

    if (Game.key.b1) jump();
    else if (leaving < 0) {
      if (Game.key.left) moveTo(8);
      else if (Game.key.right) moveTo(2);
      else if (Game.key.up) moveTo(1);
      else if (Game.key.down) moveTo(4);
      var ppx = Math.abs(pos.x - tx*32 - 17);
      var ppy = Math.abs(pos.y - ty*32 - 17);
      if (!Game.key.left && !Game.key.right && ppx > 30) tx = mx;
      if (!Game.key.up && !Game.key.down && ppy > 30) ty = my;
    }

    var pp = new Vec2(tx*32 + 17, ty*32 + 17);
    // Game.debugsprite.graphics.beginFill(0x0000FF, 1.0);
    // Game.debugsprite.graphics.drawCircle(pp.x, pp.y, 2);

    pp.sub(pos);
    pp.clamp(4*32*Game.time);

    pos.add(pp);

    if (leaving >= 0) {
      leaving = Math.max(0, leaving - 2*Game.time);
      var s = 8*leaving;
      art.cache(Std.int(2 + s)).color(0xFFFFFF).circle(s, s, s)
         .color(0x3dbf86).rect(0, s+1, 2*s+1, s/2+1);
      if (leaving == 0) {
        Game.scene.next();
      }
    } else {
      cooldown = Math.max(0, cooldown - Game.time/3.0);
      art.cache(cooldown <= 0 ? 0 : 1).color(0xFFFFFF).circle(8, 8, 8)
         .color(0x3dbf86).rect(0, 8+1, 2*8+1, cooldown <= 0 ? 8/2+1 : 8);
    }
  }
}

class Bot extends Entity {
  static var layer = 3;

  var mx: Int;
  var my: Int;
  var tx: Int;
  var ty: Int;
  var evil: Bool;

  override public function begin() {
    var d = Std.int(5*Math.random());
    if (Math.random() < 0.5) {
      mx = Math.random() < 0.5 ? d : 14 - d;
      my = Std.int(Math.random() * 15);
    } else {
      mx = Std.int(Math.random() * 15);
      my = Math.random() < 0.5 ? d : 14 - d;
    }
    tx = mx;
    ty = my;
    evil = false;
    pos = new Vec2(mx*32 + 17, my*32 + 17);

    addHitBox(Rect(0, 0, 14, 14));
  }

  function reduceX(x0: Int, y: Int, dx: Int, walk: Bool): Int {
    var x = x0;
    while (x >= 0 && x < 15) {
      var m = Game.scene.maze.map[x][y];
      if (dx == 1 && m & 2 == 2) break;
      if (dx == -1 && m & 8 == 8) break;
      if (walk && Math.random() >= 1/(1 + Math.abs(x - x0)) && (m & 1 == 0 || m & 4 == 0)) break;
      x += dx;
    }
    return x;
  }

  function reduceY(x: Int, y0: Int, dy: Int, walk: Bool): Int {
    var y = y0;
    while (y >= 0 && y < 15) {
      var m = Game.scene.maze.map[x][y];
      if (dy == 1 && m & 4 == 4) break;
      if (dy == -1 && m & 1 == 1) break;
      if (walk && Math.random() >= 1/(1 + Math.abs(y - y0)) && (m & 2 == 0 || m & 8 == 0)) break;
      y += dy;
    }
    return y;
  }

  function findNewTarget() {
    if (Game.scene.player != null) {
      var dx = EMath.sign(Game.scene.player.mx - mx);
      var dy = EMath.sign(Game.scene.player.my - my);

      if (Game.totalTime >= 2.0) {
        if (Math.random() < 0.5) {
          var k = reduceX(mx, my, EMath.sign(dx), true);
          if (k != mx) {
            tx = k;
            return;
          }
        } else {
          var k = reduceY(mx, my, EMath.sign(dy), true);
          if (k != my) {
            ty = k;
            return;
          }
        }
      }
    }
    switch(Std.int(Math.random()*4)) {
      case 0: ty = reduceY(mx, my, -1, true);
      case 1: ty = reduceY(mx, my, 1, true);
      case 2: tx = reduceX(mx, my, -1, true);
      case 3: tx = reduceX(mx, my, 1, true);
    }
  }

  function chasePlayer() {
    var pl = Game.scene.player;
    if (pl == null) return;
    evil = false;
    if (pl.mx == mx) {
      var y = reduceY(mx, my, pl.my > my ? 1 : -1, false);
      if (Math.abs(pl.my - my) <= Math.abs(y - my)) {
         evil = true;
         tx = mx;
         ty = pl.my;
      }
    }
    if (pl.my == my) {
      var x = reduceX(mx, my, pl.mx > mx ? 1 : -1, false);
      if (Math.abs(pl.mx - mx) <= Math.abs(x - mx)) {
         evil = true;
         ty = my;
         tx = pl.mx;
      }
    }
  }

  override public function update() {
    var target = new Vec2(mx*32 + 17, my*32 + 17);
    target.sub(pos);
    var step = (evil ? 5 : 2.5)*32*Game.time;
    if (target.length >= step) {
      target.clamp(step);
      pos.add(target);
    } else {
      pos = new Vec2(mx*32 + 17, my*32 + 17);
      if (Game.totalTime >= 5.0) {
        chasePlayer();
      }
      while (mx == tx && my == ty) {
        findNewTarget();
      }
      if (tx > mx) mx++;
      else if (tx < mx) mx--;
      else if (ty > my) my++;
      else if (ty < my) my--;
    }


    if (evil) {
      art.cache(0).size(3).color(0xc24079).circle(7/4,7/4,7/4);
    } else {
      art.cache(1).size(3).color(0xc24079).lcircle(7/4,7/4,7/4);
    }

    if (Game.scene.player != null &&
        hit(Game.scene.player) && Game.scene.player.leaving < 0) {
      new Sound("player explode").explosion(2).play();
      Game.scene.endGame();
    }
  }
}

class Gate extends Entity {
  static var layer = 2;

  var unlocked = false;
  var o = 1.0;
  override public function begin() {
    art.clear().color(0x444444).rect(0, 0, 20, 20).color(0x3dbf86).rect(5, 5, 10, 10);
    addHitBox(Rect(0, 0, 20, 20));
  }

  public function open() {
    unlocked = true;
  }

  override public function update() {
    if (unlocked && o > 0) {
      o = Math.max(0.0, o - 4*Game.time);
      art.clear().color(0x444444).rect(0, 0, 20, 20).color(0x3dbf86).rect(10 - 5*o, 10 - 5*o, 10*o, 10*o);
    }
    if (unlocked && Game.scene.player != null &&
        Game.scene.player.leaving <= 0 && hit(Game.scene.player)) {
      new Sound("gate").powerup(3).play();
      Game.scene.player.door();
    }
  }
}

class Key extends Entity {
  static var layer = 2;
  override public function begin() {
    art.color(0x444444).rect(0, 0, 10, 10);
    addHitBox(Rect(0, 0, 10, 10));
  }

  override public function update() {
    if (Game.scene.player != null && hit(Game.scene.player)) {
      remove();
      Game.scene.gate.open();
      new Sound("key").coin(12).play();
    }
  }
}

class Final extends Entity {
  static var layer = 10;

  var t: Text;
  var step: Float;
  override public function begin() {
    art.color(0xFFFFFF).rect(0, 0, 480, 80);
    t = new Text().size(3).color(0xff000000).text("You've reached level " + Game.scene.level);
    t.pos.x = pos.x = -240;
    t.pos.y = pos.y = 240;
    step = 0;
  }

  override public function update() {
    step = Math.min(1.0, step + Game.time/0.3);
    t.pos.x = pos.x = -240 + 480*step;
  }
}
