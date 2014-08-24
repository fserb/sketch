//@ ugl.bgcolor = 0x83CBC8

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

  override public function begin() {
    player = new Player();
    camera = new Vec2(0, 0);
    new Planet(120, 300, 30);
    new Planet(360, 150, 20);
    far = 0.0;
    planets = 0;
  }


  override public function update() {
    camera.y = Math.max(50*Game.time, 50-player.pos.y);
    camera.x = 240-player.pos.x;

    player.pos.add(camera);
    far += camera.y;

    var sub = camera.copy();
    sub.mul(0.1);
    for (obj in Game.get("Star")) {
      obj.pos.add(sub);
    }

    for (t in [ "Meteor" ]) {
      for (obj in Game.get(t)) {
        obj.pos.add(camera);
      }
    }

    for (obj in Game.get("Rope")) {
      var r: Rope = cast obj;
      obj.pos.add(camera);
      if ((r.target == null || r.target.dead) && (r.root == null || r.root.dead)) {
        obj.remove();
      }
    }

    for (obj in Game.get("Planet")) {
      obj.pos.add(camera);
      if (obj.pos.y > (480+50) && player.rope.root != obj) {
        obj.remove();
      }
    }

    if (planets*120 < far) {
      planets++;
      new Planet(80 + 320*Math.random() - 480, -50, 20 + 30*Math.random());
      new Planet(80 + 320*Math.random(), -50, 20 + 30*Math.random());
      new Planet(80 + 320*Math.random() + 480, -50, 20 + 30*Math.random());
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
    var factor = -0.001 - 0.02*(rope.targetpoint.length*rope.targetpoint.length/(480*480));

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
