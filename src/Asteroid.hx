//@ ugl.bgcolor = 0xbf1b25

import vault.ugl.*;
import vault.EMath;
import vault.Vec2;
import vault.ugl.PixelArt.C;

class Asteroid extends Game {
  static public function main() {
    Game.debug = true;
    new Asteroid("Super Asteroid", "super hot asteroid");
  }

  override public function initialize() {
    Game.orderGroups(["Maze", "Key", "Gate", "Bot", "Player", "Final", "Transition", "Text"]);
  }

  override public function end() {
    Game.one("Player").remove();
  }

  override public function begin() {
    new Player();
    new Enemy();
  }

  override public function final() {
  }

  public var realtime = 0.0;
  var timeforball = 0.0;
  override public function update() {
    if (!(Game.key.left || Game.key.right || Game.key.up)) {
      realtime = Game.time;
      Game.time /= 20.0;
    }

    timeforball -= Game.time;
    if (timeforball <= 0) {
      timeforball = 30.0;
      new Ball();
    }
  }
}

class Player extends Entity {
  override public function begin() {
    sprite.graphics.beginFill(0xFFFFFF);
    sprite.graphics.moveTo(16, 8);
    sprite.graphics.lineTo(0, 16);
    sprite.graphics.lineTo(4, 8);
    sprite.graphics.lineTo(0, 0);
    sprite.graphics.lineTo(16, 8);
    pos.x = pos.y = 240;
    addHitBox(Rect(0, 0, 16, 16));
  }

  var reload = 0.0;
  override public function update() {
    if (Game.key.left) angle -= 1.5*Math.PI*Game.main.realtime;
    if (Game.key.right) angle += 1.5*Math.PI*Game.main.realtime;
    if (Game.key.up) {
      var v = new Vec2(100*Game.time, 0);
      v.rotate(angle);
      vel.add(v);
      vel.length = Math.min(500, vel.length);
    }

    reload = Math.max(0.0, reload - Game.time);
    if (Game.key.b1 && reload <= 0.0) {
      new Bullet(this);
      reload += 0.5;
    }
    if (pos.x < -8 || pos.x > 480 + 8) pos.x = 480 - pos.x;
    if (pos.y < -8 || pos.y > 480 + 8) pos.y = 480 - pos.y;

    for (e in Game.get("Bullet")) {
      var b: Bullet = cast e;
      if (b.fromPlayer) continue;
      if (hit(b)) {
        Game.endGame();
        b.remove();
      }
    }
  }
}

class Bullet extends Entity {
  public var fromPlayer: Bool;
  var timer: Float;
  override public function new(src: Entity) {
    fromPlayer = (src == Game.one("Player"));
    super();
    pos.x = src.pos.x;
    pos.y = src.pos.y;
    angle = src.angle;
    vel.length = 200;
    vel.angle = angle;
    timer = 3;
    addHitBox(Rect(0, 0, 4, 4));
  }

  override public function begin() {
    art.color(fromPlayer ? 0xFFFFFF : 0x000000).rect(0, 0, 4, 4);
  }
  override public function update() {
    timer -= Game.time;
    if (timer < 0) {
      remove();
    }
    if (pos.x < 0 || pos.x > 480) pos.x = 480 - pos.x;
    if (pos.y < 0 || pos.y > 480) pos.y = 480 - pos.y;
  }
}

class Ball extends Entity {
  var size: Float;
  override public function new(s: Float = -1) {
    size = s > 0 ? s : 30 + 20*Math.random();
    super();
  }

  override public function begin() {
    art.color(0x0000000).circle(size, size, size);
    pos.x = -size;
    pos.y = -size;
    vel.length = 50;
    vel.angle = 2*Math.PI*Math.random();
    addHitBox(Circle(size, size, size));
  }

  override public function update() {
    for (e in Game.get("Bullet")) {
      var b: Bullet = cast e;
      if (!b.fromPlayer) continue;
      if (hit(b)) {
        remove();
        b.remove();
        if (size >= 20) {
          var b1 = new Ball(size/2);
          var b2 = new Ball(size/2);
          b1.pos.x = b2.pos.x = pos.x;
          b1.pos.y = b2.pos.y = pos.y;
          b1.vel.length = b2.vel.length = 50;
          b1.vel.angle = b.vel.angle + Math.PI/2;
          b2.vel.angle = b.vel.angle - Math.PI/2;
        }
      }
    }

    var p: Player = cast Game.one("Player");
    if (hit(p)) {
      p.remove();
      Game.endGame();
    }

    if (pos.x < -size || pos.x > 480+size) pos.x = 480 - pos.x;
    if (pos.y < -size || pos.y > 480+size) pos.y = 480 - pos.y;
  }
}


class Enemy extends Entity {
  var target: Vec2;
  var reload = 0.0;

  override public function begin() {
    sprite.graphics.beginFill(0x000000);
    sprite.graphics.moveTo(16, 8);
    sprite.graphics.lineTo(0, 16);
    sprite.graphics.lineTo(4, 8);
    sprite.graphics.lineTo(0, 0);
    sprite.graphics.lineTo(16, 8);
    pos.x = pos.y = 0;
    addHitBox(Rect(0, 0, 16, 16));
    findTarget();
  }

  function findTarget() {
    target = new Vec2(480*Math.random(), 480*Math.random());
  }

  override public function update() {
    var t = target.copy();
    t.sub(pos);

    var tangle = t.angle;

    if (angle > tangle*1.1) angle -= 1.5*Math.PI*Game.time;
    else if (angle < tangle*0.9) angle += 1.5*Math.PI*Game.time;
    else {
      var v = new Vec2(100*Game.time, 0);
      v.rotate(angle);
      vel.add(v);
      vel.length = Math.min(200, vel.length);
    }

    var p: Player = Game.one("Player");
    var pv = p.pos.copy();
    pv.sub(pos);

    var d = Math.abs(pv.angle - angle);
    reload = Math.max(0.0, reload - Game.time);
    if (d < Math.PI/6 && reload <= 0.0) {
      new Bullet(this);
      reload += 0.5;
    }

    if (pos.x < -8 || pos.x > 480 + 8) pos.x = 480 - pos.x;
    if (pos.y < -8 || pos.y > 480 + 8) pos.y = 480 - pos.y;

    for (e in Game.get("Bullet")) {
      var b: Bullet = cast e;
      if (!b.fromPlayer) continue;
      if (hit(b)) {
        remove();
        b.remove();
      }
    }
  }
}
