//@ ugl.bgcolor = 0x83CBC8

/*
- level transition
- when bump on planets, move it outside
- bump on earth
- glow colors
- text messages
*/

import vault.ugl.*;
import flash.geom.Point;
import flash.geom.Rectangle;
import vault.ds.Tuple;
import vault.EMath;
import vault.Vec2;
import vault.Ease;

class C {
  static public var white = 0xf8e6c2;
  static public var black = 0x323431;
  static public var cyan = 0x83CBC8;
  static public var darkcyan = 0x348B87;
  static public var yellow = 0xFFE0A5;
  static public var darkyellow = 0xE4B455;
  static public var red = 0xFEA4A6;
  static public var darkred = 0xE25458;
}

class LD30 extends Micro {
  var camera: Vec2;
  var far: Float;
  public var planets: Int;
  public var linked: Int;
  var level: Int;
  public var player: Player;
  static public function main() {
    new Sound("hit").explosion(1238);
    new Sound("connect").powerup(1246);
    new Sound("leave").hit(1259);
    new Sound("done").powerup(1274);

    Micro.baseColor = 0x000000;
    new LD30("Tin Can Universe", "");
  }

  function buildPlanets(total:Int) {
    var n = 0;
    var skipped = 0;

    var dim = Math.ceil(total/5);
    var dimx = Math.ceil(Math.sqrt(dim));
    var dimy = Math.ceil(dim/dimx);
    trace(total + " => " + dimx + ", " + dimy);

    while (n < total && skipped < 10*total) {
      var x = (240 - dimx*480/2) + dimx*480*Math.random();
      var y = -480*dimy + 480*dimy*Math.random();
      var s = 30 + 20*Math.random();

      var valid = true;
      for (e in Game.get("Planet")) {
        var p:Planet = cast e;
        var d = p.pos.distance(Vec2.make(x,y)).length;
        if (d < (s + p.size + 60)) {
          valid = false;
          break;
        }
      }

      if (valid) {
        new Planet(x, y, s);
        n++;
      } else {
        skipped++;
      }
    }

    planets = n;
    new DropZone(dimx, dimy);
  }

  override public function begin() {
    level = 0;
    buildLevel();
  }

  var xxx = 1234;

  override public function update() {
    if (Game.key.b1_pressed) {
      trace(xxx);
      new Sound(""+xxx).powerup(xxx).play();
      xxx++;
    }

    camera.x = 240-player.pos.x;
    camera.y = 240-player.pos.y;

    for (t in [ "Player", "Rope", "Planet", "Earth", "DropZone", "ZoneBar" ]) {
      for (obj in Game.get(t)) {
        obj.pos.add(camera);
      }
    }
  }

  static var LEVELS = [ 3, 5, 8, 10, 15, 20, 30, 50 ];

  public function buildLevel() {
    Game.clear(null);

    player = new Player();
    camera = new Vec2(0, 0);
    new Earth();

    planets = LEVELS[level];

    buildPlanets(planets);
    new Timer(10 + planets*1.5);
    new Pieces();
  }

  public function nextLevel() {
    level++;
    buildLevel();
  }

  public function failGame() {
    /*endGame();*/
  }
}

class Pieces extends Entity {
  static var layer = 1000;
  override public function begin() {
    pos.x = 60;
    pos.y = 10;
    alignment = TOPLEFT;

    update();
  }

  override public function update() {
    gfx.clear();
    gfx.fill(C.yellow, 0.75);

    var i = 0;
    var cnt = 0;
    for (obj in Game.get("Planet")) {
      var p:Planet = cast obj;
      if (p.link > 0) {
        p.linktimer = Math.min(1.0, p.linktimer + Game.time);
        var s = Std.int(10*Ease.elasticOut(p.linktimer));
        gfx.rect(2 + i*358/Game.scene.planets, 5 - s/2, 358/Game.scene.planets, s);
        if (p.linktimer >= 1.0) {
          cnt++;
        }
      }
      i++;
    }
    gfx.rect(0, 0, 2, 10).rect(358, 0, 2, 10).rect(0, 4, 360, 2);

    Game.scene.linked = cnt;
  }
}

class Timer extends Entity {
  static var layer = 1000;
  var total: Float;
  var current: Float;
  var flip: Float = 0.0;
  override public function begin() {
    total = args[0];
    current = 0.0;
    pos.x = 240;
    pos.y = 460;
    update();
  }

  override public function update() {
    current += Game.time;
    gfx.clear();
    gfx.fill(C.black, 0.2).rect(0, 0, 360, 10);
    var r = Math.min(1.0, current/total);
    var c = C.darkred;
    if (r > 0.8) {
      if (flip > 1.0) {
        c = C.darkyellow;
        if (flip >= 2.0) {
          flip -= 2.0;
        }
      }
      flip += Game.time/0.1;
    }
    gfx.fill(c, 1.0).rect(0, 0, 360*r, 10);
    if (current >= total) {
      Game.scene.failGame();
    }
  }
}

class Player extends Entity {
  static var layer = 20;
  public var rope: Rope;
  override public function begin() {
    pos.x = pos.y = 240;
    gfx.size(40, 40).fill(C.black, 1.0)
      .circle(20, 20 - 4, 8)
      .circle(20, 20 + 4, 8)
      .circle(20 - 8, 20 + 8, 4)
      .circle(20 + 8, 20 + 8, 4)
      .circle(20, 20, 8);
    effect.glow(5, C.white);

    rope = new Rope(this, new Vec2(240, 480));

    addHitBox(Rect(12, 8, 16, 24));
  }

  override public function update() {
    var mv = new Vec2(0,0);
    if (Game.key.left) {  mv.x -= 1; }
    if (Game.key.right) { mv.x += 1; }
    if (Game.key.up) { mv.y -= 1; }
    if (Game.key.down) { mv.y += 1; }
    mv.normalize();
    mv.mul(1000);
    acc.add(mv);

    var fric = vel.copy();
    fric.mul(-1);
    acc.add(fric);

    var drag = vel.copy();
    var f = rope.targetpoint.length/(480+240);
    var factor = -0.001 - 0.01*f*f;

    drag.mul(factor*vel.length);
    acc.add(drag);

    angle = vel.angle + Math.PI/2;
  }
}

class Rope extends Entity {
  static var layer = 10;
  public var target: Entity;
  public var root: Planet;
  var rootdir: Bool;
  var rootpos: Vec2;
  public var targetpoint: Vec2;
  var active: Bool;
  var prev: Rope;
  var roll: Float;
  override public function begin() {
    active = (args[0] != null);
    draw();
    pos.x = args[1].x;
    pos.y = args[1].y;
    target = args[0];
    if (target != null) {
      stretchTo(target.pos);
    }
    root = null;
    prev = null;
    roll = Math.PI/4;
  }

  function draw() {
    gfx.clear();
    gfx.size(10, 10).fill(active ? C.black : C.white, 0.5).rect(3.5, 0, 3, 10);
    if (active) {
      effect.glow(5, C.white);
    }
  }

  function stretchTo(t: Vec2) {
    targetpoint = t.copy();
    targetpoint.sub(pos);
    angle = targetpoint.angle + Math.PI/2;
    sprite.scaleY = targetpoint.length/10;
    deltasprite.x = targetpoint.x/2.0;
    deltasprite.y = targetpoint.y/2.0;

    clearHitBox();
    if (active) {
      addHitBox(Rect(3.5, 0, 3, targetpoint.length));
    }
  }

  override public function update() {
    if (!active) {
      return;
    }
    Game.scene.player.rope = this;

    if (root != null) {
      var t = root.getTangents(target.pos);
      pos = this.rootdir ? t.first : t.second;

      var a0 = rootpos.distance(root.pos);
      var a1 = pos.distance(root.pos);

      var ang = (a1.angle - a0.angle + 2*Math.PI) % (2*Math.PI);
      if (!this.rootdir) {
        ang = 2*Math.PI - ang;
      }
      if (ang > Math.PI) {
        ang -= 2*Math.PI;
      }
      rootpos = pos;
      roll += ang;
      if (roll < 0) {
        var r = new Rope(Game.scene.player, prev.pos);
        r.prev = prev.prev;
        r.root = prev.root;
        r.rootdir = prev.rootdir;
        r.rootpos = prev.rootpos;
        r.roll = prev.roll;

        root.link -= 1;
        root.draw();
        new Sound("leave").play();

        prev.remove();
        remove();
        return;
      }
    }

    stretchTo(target.pos);

    for (e in Game.get("Planet")) {
      var p:Planet = cast e;
      if (root != p && hit(e)) {
        var tg = p.getGoodTangent(pos, target.pos);

        var r = new Rope(target, tg);
        r.prev = this;
        r.root = p;
        r.rootdir = tg.distance(p.pos).cross(pos.distance(p.pos)) <= 0;
        r.rootpos = tg;

        active = false;
        target = p;
        draw();
        stretchTo(tg);
        if (p.link <= 0) p.linktimer = 0.0;
        p.link += 1;
        new Sound("connect").play();
        Game.delay(0.01);
        p.draw();
      }
    }
  }
}

class Planet extends Entity {
  static var layer = 15;
  public var link: Int;
  public var size: Int;
  public var linktimer: Float;

  override public function begin() {
    this.size = args[2];
    pos.x = args[0];
    pos.y = args[1];
    link = 0;
    draw();
    addHitBox(Circle(10 + size, 10 + size, size));
    new PlanetShow(this);
  }

  public function draw() {
    gfx.clear();
    gfx.size(2*size + 20, 2*size + 20).fill(link > 0 ? C.white : C.black).circle(10 + size, 10 + size, size);
    effect.glow(5, link > 0 ? C.white : C.black);
  }

  public function getTangents(p:Vec2): Tuple2<Vec2, Vec2> {
    var dir = pos.copy();
    dir.sub(p);
    var angle = dir.angle;

    var tan1 = new Vec2(dir.length, size-1);
    var tan2 = new Vec2(dir.length, -(size-1));
    tan1.rotate(angle);
    tan2.rotate(angle);
    tan1.add(p);
    tan2.add(p);

    return Tuple.two(tan1, tan2);
  }

  public function getGoodTangent(p: Vec2, t: Vec2): Vec2 {
    var tan = getTangents(p);

    var d1 = tan.first.distance(t).length;
    var d2 = tan.second.distance(t).length;

    return (d1 <= d2) ? tan.first : tan.second;
  }

  override public function update() {
    if (hit(Game.scene.player)) {
      var p = Game.scene.player;
      var x = p.pos.copy();
      x.sub(pos);
      x.normalize();

      x.mul(7000);
      p.acc.add(x);
      Game.shake(0.2);
      Micro.flash(C.white, 0.05);
      new Sound("hit").play();

    }
  }

}

class PlanetShow extends Entity {
  static var layer = 450;
  var target: Planet;

  override public function begin() {
    target = args[0];
  }

  override public function update() {
    pos.x = target.pos.x;
    pos.y = target.pos.y;

    if (target.link <= 0 && (pos.x < 0 || pos.y < 0 || pos.x >= 480 || pos.y >= 480)) {
      var dist = pos.distance(Vec2.make(240, 240)).length - 240;
      var op = 1.0 - Math.max(0.0, Math.min(0.9, dist/(480*2)));

      gfx.clear().fill(C.black, op).mt(0, 0).lt(7.5, 5).lt(0, 10).lt(0, 0);

      pos.x = Math.max(10, Math.min(470, pos.x));
      pos.y = Math.max(10, Math.min(470, pos.y));

      var v = pos.distance(new Vec2(240, 240));
      angle = v.angle;

    } else {
      gfx.clear();
    }
  }
}

class Earth extends Entity {
  static var layer = 20;
  override public function begin() {
    gfx.fill(C.white).circle(300, 300, 300);
    pos.x = 240;
    pos.y = 710;
  }
}

class ZoneBar extends Entity {
  override public function begin() {
    pos.x = args[0];
    pos.y = args[1];
    alignment = TOPLEFT;

    if (args[2]) {
      var p = 0;
      var b = false;
      while (p < args[3]) {
        if (b) {
          gfx.fill(C.black, 0.1).rect(p, 0, 10, 4);
        }
        b = !b;
        p += 10;
      }
    } else {
      var p = 0;
      var b = false;
      while (p < args[3]) {
        if (b) {
          gfx.fill(C.black, 0.1).rect(0, p, 4, 10);
        }
        b = !b;
        p += 10;
      }
    }
  }
}

class DropZone extends Entity {
  static var layer = 10;
  override public function begin() {
    var sizex = args[0]*480 + 240;
    var sizey = args[1]*480 + 240;

    pos.x = (240 - sizex/2);
    pos.y = -sizey + 120;
    alignment = TOPLEFT;

    new ZoneBar(pos.x, pos.y, true, sizex);
    new ZoneBar(pos.x, pos.y + sizey, true, sizex);
    new ZoneBar(pos.x, pos.y, false, sizey);
    new ZoneBar(pos.x + sizex, pos.y, false, sizey);

    addHitBox(Rect(0, 0, sizex, sizey));
  }

  override public function update() {
    if (!hit(Game.scene.player)) {
      if (Game.scene.linked >= Game.scene.planets) {
        new Sound("done").play();
        Game.scene.nextLevel();
      }
    }
  }

}
