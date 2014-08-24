//@ ugl.bgcolor = 0x83CBC8

/*
- win condition
- lose when time up
- start new level
- sounds
- when bump on planets, move it outside
- bump on earth
- glow colors
- time bonus

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
  var planets: Int;
  public var player: Player;
  static public function main() {
    Micro.baseColor = 0x000000;
    new LD30("Tin Can Universe", "");
  }

  function buildPlanets(total:Int) {
    var n = 0;
    var skipped = 0;

    var dim = Math.ceil(Math.sqrt(total/5));

    while (n < total && skipped < 10*total) {
      var x = (240 - dim*480/2) + dim*480*Math.random();
      var y = -480*dim + 480*dim*Math.random();
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
  }


  override public function begin() {
    player = new Player();
    camera = new Vec2(0, 0);
    new Earth();

    buildPlanets(50);
    new Timer(20);
  }

  override public function update() {
    camera.x = 240-player.pos.x;
    camera.y = 240-player.pos.y;

    player.pos.add(camera);

    for (t in [ "Rope", "Planet", "Earth" ]) {
      for (obj in Game.get(t)) {
        obj.pos.add(camera);
      }
    }
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
    draw();
    pos.x = 240;
    pos.y = 460;
  }

  function draw() {
    gfx.clear();
    gfx.fill(C.black, 0.2).rect(0, 0, 360, 10);
    var r = Math.min(1.0, current/total);
    var c = C.darkyellow;
    if (r > 0.75) {
      c = C.darkred;
      if (r > 0.9) {
        if (flip > 1.0) {
          c = C.darkyellow;
          if (flip >= 2.0) {
            flip -= 2.0;
          }
        }
        flip += Game.time/0.1;
      }
    }
    gfx.fill(c, 1.0).rect(0, 0, 360*r, 10);
  }

  override public function update() {
    current += Game.time;
    draw();
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
    var factor = -0.001 - 0.01*(rope.targetpoint.length*rope.targetpoint.length/(480*480));

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
        p.link += 1;
        p.draw();
      }
    }
  }
}

class Planet extends Entity {
  static var layer = 15;
  public var link: Int;
  public var size: Int;

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
