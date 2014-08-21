//@ ugl.bgcolor = 0x000000
//@ ugl.skip

// TODO:


import vault.ugl.*;
import vault.EMath;
import vault.Vec2;

typedef C = Color.ColorsArne;

class Jebediah extends Micro {
  static public function main() {
    new Jebediah("Jebediah's Revenge", "");
  }

  public var player: Player;
  public var energy: Energy;

  override public function begin() {
    player = new Player();
    new Trajectory();
    energy = new Energy();
    new Planet(240, 400, 8);
    new Planet(480, 0, 6);
    new Planet(0, 0, 7);
    Game.orderGroups(["Planet", "Jebediah"]);

    // new Asteroid();
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

    // if (Game.get("Asteroid").length == 0) {
    //   new Asteroid();
    // }

  }
}

class Energy extends Entity {
  override public function begin() {
    pos.x = 50;
    pos.y = 10;
  }

  override public function update() {
    var v = Game.scene.player.energy;
    art.size(1, 80, 4)
      .color(0x444444).rect(0, 0, 80, 4)
      .color(v >= 15 ? C.lightbrown : C.red).rect(0, 0, 80*v/100.0, 4);
  }
}

class Trajectory extends Entity {
  override public function update() {
    var p = Game.scene.player;
    pos.x = 0;
    pos.y = 0;

    var g = sprite.graphics;
    g.clear();

    g.lineStyle(1, 0x00FF00, 0.5);

    var x = p.pos.x;
    var y = p.pos.y;
    g.moveTo(x, y);

    var pv = p.vel.copy();
    var va = new Vec2(0, 0);

    var total = 10.0;
    var dt = 0.1;
    while (total >= 0.0) {

      if (p.closest != null) {
        va = p.closest.attract(new Vec2(x, y), dt);
      }

      x += dt*(pv.x + va.x/2.0);
      y += dt*(pv.y + va.y/2.0);
      total -= dt;
      pv.add(va);
      g.lineTo(x, y);

    }
    deltasprite.x = sprite.width/2.0;
    deltasprite.y = sprite.height/2.0;
  }
}

class Player extends Entity {
  public var energy: Float;
  public var closest: Planet;
  override public function begin() {
    pos.set(240, 240);

    art.size(4, 5, 5).obj([C.darkgrey, C.darkgreen, C.lightbrown, C.green ],
      ".000.
       00300
       00100
       00000
       02220");
    addHitBox(Rect(0, 0, 20, 20));
    energy = 100.0;
    closest = null;
  }

  public function explode() {
    new Particle().xy(pos.x, pos.y).count(500).size(4).color(C.darkgrey)
      .speed(10, 30).delay(0).duration(1, 2);
    Game.scene.end();
  }

  override public function update() {
    if (Game.key.up && energy > 0) {
      energy -= 10*Game.time;
      var v = new Vec2(0, vel.length == 0 ? -50 : -5);
      v.rotate(angle);
      accelerate(v);
      var b = new Vec2(0, 15);
      b.rotate(angle);
      new Particle().xy(pos.x + b.x, pos.y + b.y).count(1)
        .size(5).color(C.lightbrown).delay(0).duration(1,0.2)
        .direction(angle + Math.PI/2 - Math.PI/8, Math.PI/4).speed(50, 10);
    }

    if (Game.key.left) angle -= 2*Math.PI*Game.time/2.0;
    if (Game.key.right) angle += 2*Math.PI*Game.time/2.0;
    if (angle < 0) angle += 2*Math.PI;
    if (angle >= 2*Math.PI) angle -= 2*Math.PI;

    var mindist = 1e99;
    closest = null;
    for (p in Game.get("Planet")) {
      var d = pos.distance(p.pos).length;
      if (d < mindist) {
        mindist = d;
        closest = cast p;
      }
    }
    if (Game.key.b1) {
      var va = closest.attract(pos, Game.time);

      var v = closest.pos.copy();
      v.sub(pos);
      va.mul(v.length);
      va.angle = v.angle - Math.PI/2;

      // va.sub(vel);
      // va.normalize();
      // accelerate(va);
      vel.x = va.x;
      vel.y = va.y;
    }
    // trace(mindist);
  }
}

class Planet extends Entity {
  var size: Int;
  var pcolor: UInt;
  override public function new(x: Float, y: Float, size: Int) {
    this.size = size;
    super();
    pos.x = x;
    pos.y = y;
  }
  override public function begin() {
    pcolor = C.purple;
    art.size(5, size*2, size*2).color(pcolor).circle(size, size, size);
    pos.set(240, 240);
    addHitBox(Circle(sprite.width/2.0, sprite.height/2.0, sprite.width/2.0));
  }

  public function attract(p: Vec2, t: Float): Vec2 {
    var v = pos.copy();
    v.sub(p);
    var dist = v.length;
    var a = t*1000000.0/(dist * dist);
    v.mul(a/dist);
    return v;
  }

  override public function update() {
    var p:Player = Game.scene.player;
    var v = pos.copy();
    v.sub(p.pos);
    var dist = v.length;

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

    if (p.closest == this) {
      p.accelerate(attract(p.pos, Game.time));
    }

    var col = Color.lerp(C.purple, 0x222222, (dist - 120)/120.0);
    if (col != pcolor) {
      pcolor = col;
      art.size(5,size*2, size*2).color(pcolor).circle(size, size, size);
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

    art.size(5,size*2, size*2)
      .color(C.darkgrey, 0x333333, 35).circle(size, size, size);
    addHitBox(Circle(sprite.width/2.0, sprite.height/2.0, sprite.width/2.0));
  }

  function explode() {
    new Particle().xy(pos.x, pos.y).count(200).size(5).color(0x333333)
      .speed(10, 30).delay(0).duration(1, 0.5);
    remove();
  }

  override public function update() {
    for (p in Game.get("Planet")) {
      var pl: Planet = cast p;
      var v:Vec2 = p.pos.copy();
      v.sub(pos);
      var dist = v.length;
      if (dist > 120) continue;
      accelerate(pl.attract(pos, Game.time));

      if (hit(p)) {
        explode();
      }
    }

    if (hit(Game.scene.player)) {
      trace("asteroid");
      explode();
      Game.scene.player.explode();
    }

    if (pos.x < -sprite.width/2 || pos.x > 480+sprite.width/2 ||
        pos.y < -sprite.width/2 || pos.y > 480+sprite.width/2) {
      remove();
    }
  }
}
