//@ mgl.bgcolor = 0x000000

import vault.ugl.*;
import vault.EMath;
import vault.Vec2;
import vault.ugl.PixelArt.C;

class Jebediah extends Game {
  static public function main() {
    Game.debug = true;
    new Jebediah("Jebediah's Revenge", "");
  }

  public var player: Player;
  public var energy: Energy;

  override public function initialize() {
    Game.orderGroups(["Planet", "Jebediah"]);
  }

  override public function begin() {
    player = new Player();
    energy = new Energy();
    new Planet(240, 400, 8);
    new Planet(480, 0, 6);
    new Planet(0, 0, 7);

    new Asteroid();
  }

  override public function end() {
    player.remove();
  }

  override public function update() {
    var d = new Vec2(240, 240);
    d.sub(player.pos);

    for (p in Game.get("Asteroid")) {
      p.pos.add(d);
    }
    for (p in Game.get("Planet")) {
      p.pos.add(d);
    }
    player.pos.add(d);

    if (Game.get("Asteroid").length == 0) {
      new Asteroid();
    }

  }
}

class Energy extends Entity {
  override public function begin() {
    pos.x = 50;
    pos.y = 10;
  }

  override public function update() {
    var v = Game.main.player.energy;
    art.size(80, 4, 1)
      .color(0x444444).rect(0, 0, 80, 4)
      .color(v >= 15 ? C.lightbrown : C.red).rect(0, 0, 80*v/100.0, 4);
  }
}

class Player extends Entity {
  public var energy: Float;
  override public function begin() {
    pos.set(240, 240);

    art.size(5, 5, 4).obj([C.darkgrey, C.darkgreen, C.lightbrown, C.green ],
      ".000.
       00300
       00100
       00000
       02220");
    addHitBox(Rect(0, 0, 20, 20));
    energy = 100.0;
  }

  public function explode() {
    new Particle().xy(pos.x, pos.y).count(Const(500))
      .size(Const(4)).color(C.darkgrey)
      .speed(Rand(10, 30)).delay(Const(0)).duration(Rand(1, 2));
    Game.main.end();
  }

  override public function update() {
    if (Game.key.up && energy > 0) {
      energy -= 10*Game.time;
      var v = new Vec2(0, vel.length == 0 ? -50 : -3);
      v.rotate(angle);
      accelerate(v);
      var b = new Vec2(0, 15);
      b.rotate(angle);
      new Particle().xy(pos.x + b.x, pos.y + b.y).count(Const(1))
        .size(Const(5)).color(C.lightbrown)
        .direction(Rand(angle + Math.PI/2 - Math.PI/8, Math.PI/4)).speed(Rand(50, 10))
        .delay(Const(0)).duration(Rand(1,0.2));
    }

    if (Game.key.left) angle -= 2*Math.PI*Game.time/2.0;
    if (Game.key.right) angle += 2*Math.PI*Game.time/2.0;
    if (angle < 0) angle += 2*Math.PI;
    if (angle >= 2*Math.PI) angle -= 2*Math.PI;

    var mindist = 1e99;
    var closest = null;
    for (p in Game.get("Planet")) {
      var d = pos.distance(p.pos);
      if (d < mindist) {
        mindist = d;
        closest = p;
      }
    }
    if (Game.key.b1) {
      var v = closest.pos.copy();
      v.sub(pos);
      var tar = new Vec2(1,0);
      tar.length = Math.sqrt(9000/v.length);
      tar.angle = v.angle - Math.PI/2;
      tar.sub(vel);
      tar.normalize();
      tar.mul(2);
      accelerate(tar);
    }
    // trace(mindist);

    var g = Game.debugsprite.graphics;
    g.clear();
    g.lineStyle(1, 0xFF0000, 0.3);
    g.moveTo(pos.x, pos.y);
    g.lineTo(pos.x + vel.x, pos.y + vel.y);

    if (closest != null) {
      g.lineStyle(1, 0x00FF00, 0.3);
      g.moveTo(pos.x, pos.y);
      g.lineTo(closest.pos.x, closest.pos.y);
    }
  }
}

class Planet extends Entity {
  var size: Int;
  var pcolor: Int;
  override public function new(x: Float, y: Float, size: Int) {
    this.size = size;
    super();
    pos.x = x;
    pos.y = y;
  }
  override public function begin() {
    pcolor = C.purple;
    art.size(size*2, size*2, 5).color(pcolor).circle(size, size, size);
    pos.set(240, 240);
    addHitBox(Circle(sprite.width/2.0, sprite.height/2.0, sprite.width/2.0));
  }

  override public function update() {
    var p:Player = Game.main.player;
    var v = pos.copy();
    v.sub(p.pos);
    var dist = v.length;

    // debugHit = size == 7;
    if (hit(p)) {
      if(p.vel.length > 120) {
        trace("speed " + pos);
        p.explode();
      }

      p.vel.x = p.vel.y = 0;
      var t = v.angle - Math.PI/2.0;

      var dangle = p.angle - t;
      dangle = (dangle + Math.PI) % (2*Math.PI) - Math.PI;
      dangle = Math.abs(dangle);
      if (dangle > Math.PI/4) {
        trace("angle " + p.angle + " - " + t + " = " + dangle);
        p.explode();
      }
      p.angle = t;

      p.energy = Math.min(100, p.energy + Game.time*5);

      return;
    }

    var a = 8000/(dist * dist);
    var va = v.copy();
    va.mul(a/dist);
    p.accelerate(va);

    var col = C.lerp(C.purple, 0x222222, (dist - 120)/120.0);
    if (col != pcolor) {
      pcolor = col;
      art.size(size*2, size*2, 5).color(pcolor).circle(size, size, size);
    }
  }
}

class Asteroid extends Entity {
  var size: Int;
  override public function begin() {
    var r = 480*Math.random();
    switch(Std.int(4*Math.random())) {
      case 0: pos.x = r; pos.y = 0;
      case 1: pos.x = 480; pos.y = r;
      case 2: pos.x = r; pos.y = 480;
      case 3: pos.x = 0; pos.y = r;
    }
    size = Std.int(1 + Math.random()*4);

    vel.x = 240 - pos.x;
    vel.y = 240 - pos.y;
    vel.normalize();
    vel.length = 20 + Math.random()*50;

    art.size(size*2, size*2, 5)
      .color(C.darkgrey, 0x333333, 35).circle(size, size, size);
    addHitBox(Circle(sprite.width/2.0, sprite.height/2.0, sprite.width/2.0));
  }

  function explode() {
    new Particle().xy(pos.x, pos.y).count(Const(200))
      .size(Const(5)).color(0x333333)
      .speed(Rand(10, 30)).delay(Const(0)).duration(Rand(1, 0.5));
    remove();
  }

  override public function update() {
    for (p in Game.get("Planet")) {
      var v:Vec2 = p.pos.copy();
      v.sub(pos);
      var dist = v.length;
      var a = 8000/(dist * dist);
      v.mul(a/dist);
      accelerate(v);

      if (hit(p)) {
        explode();
      }
    }

    if (hit(Game.main.player)) {
      trace("asteroid");
      explode();
      Game.main.player.explode();
    }

    if (pos.x < -sprite.width/2 || pos.x > 480+sprite.width/2 ||
        pos.y < -sprite.width/2 || pos.y > 480+sprite.width/2) {
      remove();
    }
  }
}

