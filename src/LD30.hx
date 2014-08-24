//@ ugl.bgcolor = 0x83CBC8

/*
ideas:
- random position hashi
-
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
  public var player: Player;
  static public function main() {
    Micro.baseColor = 0x000000;
    new LD30("Tin Can Universe", "");
  }

  override public function begin() {
    player = new Player();
    camera = new Vec2(0, 0);
    new Planet(120, 300, 30);
    new Planet(360, 150, 20);
    new Probe(75, 75);
  }

  var cnt = 0.0;

  override public function update() {

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
    var factor = -0.001 - 0.05*(rope.targetpoint.length*rope.targetpoint.length/(480*480));

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
  var size: Int;

  override public function begin() {
    this.size = args[2];
    pos.x = args[0];
    pos.y = args[1];
    link = 0;
    draw();
    addHitBox(Circle(10 + size, 10 + size, size));
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
}

class Probe extends Entity {
  static var layer = 250;
  var target: Vec2;
  var radar: Radar;
  var boost: Float = 0.0;

  static public function pentagon(center:Vec2, size: Float): Array<Vec2> {
    var pts = new Array<Vec2>();
    var an = 2*Math.PI/5;
    for (i in 0...5) {
      pts.push(new Vec2(center.x + size*Math.cos(an*i), center.y + size*Math.sin(an*i)));
    }
    return pts;
  }

  override public function begin() {
    var pts = pentagon(new Vec2(50, 50), 12);
    addHitBox(Polygon(pts));
    pos.x = args[0];
    pos.y = args[1];

    gfx.size(100, 100).fill(C.darkred);
    gfx.mt(pts[0].x, pts[0].y);
    for (i in 1...5) {
      gfx.lt(pts[i].x, pts[i].y);
    }
    radar = new Radar(this);
    target = new Vec2(480*Math.random(), 480*Math.random());
  }

  override public function update() {
    angle += Game.time*Math.PI/3;

    var d = target.distance(pos);
    d.length = Math.min(boost > 0 ? 250 : 50, d.length/Game.time);
    if (boost > 0) boost -= Game.time;
    vel = d;
    if (d.length < 10) {
      target = new Vec2(480*Math.random(), 480*Math.random());
    }

    if (radar.hitGroup("Rope") != null || radar.hitGroup("Player") != null) {
      target = Game.scene.player.pos.copy();
      boost = 5;
      trace("boost");
    }
  }

}

class Radar extends Entity {
  static var layer = 250;

  var probe: Probe;
  var size: Float;
  var dir: Bool = true;
  override public function begin() {
    probe = args[0];
    size = 12;
    draw();
  }

  function draw() {
    var pts = Probe.pentagon(new Vec2(100, 100), size);
    gfx.clear();
    gfx.size(200, 200).line(1, C.darkred);
    gfx.mt(pts[0].x, pts[0].y);
    for (i in 1...5) {
      gfx.lt(pts[i].x, pts[i].y);
    }

    clearHitBox();
    addHitBox(Polygon(pts));
  }

  override public function update() {
    pos.x = probe.pos.x;
    pos.y = probe.pos.y;
    angle = probe.angle;

    if (dir) {
      size = Math.min(70, size + Game.time*50/2);
      if (size >= 70) dir = false;
    } else {
      size = Math.max(12, size - Game.time*50/2);
      if (size <= 12) dir = true;
    }
    draw();
  }
}
