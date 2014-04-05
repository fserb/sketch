//@ ugl.bgcolor = 0xbf1b25

/*
TODO
- enemy waves
- sound
*/

import vault.ugl.*;
import vault.EMath;
import vault.Vec2;
import vault.ugl.PixelArt.C;

class Asteroid extends Game {
  public var score = 0.0;
  var display: Text;
  static public function main() {
    Game.debug = true;
    new Asteroid("Super Asteroid", "super hot asteroid");
  }

  override public function initialize() {
    Game.orderGroups(["Particle", "Ball", "Enemy", "Player", "Bullet", "Text"]);
  }

  override public function end() {
    Game.one("Player").remove();
  }

  override public function begin() {
    new Player();
    score = 0.0;
    timeforball = 0.0;
    display = new Text().color(0xFFFFFF).xy(10, 10).align(TOP_LEFT).size(2);
  }

  override public function final() {
  }

  public var realtime = 0.0;
  var timeforball = 0.0;
  override public function update() {
    realtime = Game.time;
    if (!(Game.key.up)) {
      Game.time /= 50.0;
    }

    timeforball -= Game.time;
    if (timeforball <= 0 || Game.key.b2_pressed) {
      timeforball = 10.0;
      new Ball();
      new Enemy();
    }

    score += Game.time;
    display.text(""+Std.int(score));
  }
}

class Player extends Entity {
  override public function begin() {
    sprite.graphics.beginFill(0xFFFFFF);
    sprite.graphics.moveTo(24, 12);
    sprite.graphics.lineTo(0, 24);
    sprite.graphics.lineTo(6, 12);
    sprite.graphics.lineTo(0, 0);
    sprite.graphics.lineTo(24, 12);
    pos.x = pos.y = 240;
    addHitBox(Rect(0, 0, 24, 24));
  }

  public var reload = 0.0;
  override public function update() {
    if (Game.key.left) angle -= 1.5*Math.PI*Game.main.realtime;
    if (Game.key.right) angle += 1.5*Math.PI*Game.main.realtime;
    if (Game.key.up) {
      var v = new Vec2(200*Game.time, 0);
      v.rotate(angle);
      vel.add(v);
      vel.length = Math.min(100, vel.length);
    }

    reload = Math.max(0.0, reload - Game.time);
    if (Game.key.b1 && reload <= 0.0) {
      new Bullet(this);
      reload += 0.3;
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
    angle = src.angle;
    pos.x = src.pos.x + 12*Math.cos(angle);
    pos.y = src.pos.y + 12*Math.sin(angle);
    vel.length = 300;
    vel.angle = angle;
    timer = 2;
    addHitBox(Rect(0, 0, 10, 4));
  }

  override public function begin() {
    var g = sprite.graphics;
    g.beginFill(fromPlayer ? 0xFFFFFF : 0x000000);
    g.moveTo(0, 2);
    g.lineTo(10, 0);
    g.lineTo(10, 4);
    g.lineTo(0, 2);
  }
  override public function update() {
    timer -= Game.time;
    if (timer < 0) {
      remove();
    }
    if (pos.x < 0 || pos.x > 480) pos.x = 480 - pos.x;
    if (pos.y < 0 || pos.y > 480) pos.y = 480 - pos.y;

    for (e in Game.get("Bullet")) {
      var b: Bullet = cast e;
      if (b == this) continue;
      if (b.fromPlayer == fromPlayer) continue;
      if (hit(b)) {
        remove();
        b.remove();
      }
    }
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

    if (Math.random() < 0.5) {
      pos.x = 480*Math.random();
      pos.y = Math.random() < 0.5 ? -size : 480+size;
    } else {
      pos.x = Math.random() < 0.5 ? -size : 480+size;
      pos.y = 480*Math.random();
    }

    vel.length = 100;
    vel.angle = 2*Math.PI*Math.random();
    addHitBox(Circle(size, size, size));
  }

  override public function update() {
    for (e in Game.get("Bullet")) {
      var b: Bullet = cast e;
      if (!b.fromPlayer) continue;
      if (hit(b)) {
        Game.main.score += 2;
        new Text().xy(pos.x, pos.y).duration(1).move(0, -20).color(0xFFFFFF).text("+2");
        new Particle().color(0x000000)
          .count(Rand(size*2, size)).xy(pos.x, pos.y)
          .size(Rand(4,size/2)).speed(Rand(0, 100))
          .duration(Rand(1.5, 0.5));
        remove();
        b.remove();
        if (size >= 30) {
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
    sprite.graphics.moveTo(24, 12);
    sprite.graphics.lineTo(0, 24);
    sprite.graphics.lineTo(6, 12);
    sprite.graphics.lineTo(0, 0);
    sprite.graphics.lineTo(24, 12);
    if (Math.random() < 0.5) {
      pos.x = 480*Math.random();
      pos.y = Math.random() < 0.5 ? 0 : 480;
    } else {
      pos.x = Math.random() < 0.5 ? 0 : 480;
      pos.y = 480*Math.random();
    }

    addHitBox(Rect(0, 0, 24, 24));
    findTarget();
  }

  function findTarget() {
    target = new Vec2(480*Math.random(), 480*Math.random());
    target.add(Game.one("Player").pos);
    target.mul(0.5);
  }

  override public function update() {
    Game.debugsprite.graphics.beginFill(0x00FF00);
    Game.debugsprite.graphics.drawCircle(target.x, target.y, 5);

    var t = target.distance(pos);

    if (t.length < 32) {
      findTarget();
    }

    var delta = t.angle - angle;
    delta = Math.PI - Math.abs(Math.abs(delta) - Math.PI);

    var inc = 1.5*Math.PI*Game.time;

    if (delta >= inc) angle -= inc;
    else if (delta <= -inc) angle += inc;

    if (Math.abs(delta) < Math.PI/6) {
      var v = new Vec2(200*Game.time, 0);
      v.rotate(angle);
      vel.add(v);
      vel.length = Math.min(100, vel.length);
    }

    var p: Player = Game.one("Player");
    var pv = p.pos.distance(pos);

    var pd = Math.abs(Math.PI - Math.abs(Math.abs(pv.angle - angle) - Math.PI));

    if (pd >= Math.PI/2 && Math.abs(delta) <= Math.PI/2) {
      findTarget();
    }

    reload = Math.max(0.0, reload - Game.time);
    if (pd < Math.PI/12 && reload <= 0.0) {
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
        Game.main.score += 10;
        new Text().xy(pos.x, pos.y).duration(1).move(0, -20).color(0xFFFFFF).text("+10");
        new Particle().color(0x000000)
          .count(Rand(20, 10)).xy(pos.x, pos.y)
          .size(Rand(3,2)).speed(Rand(5, 15))
          .duration(Rand(1.0, 0.5));
      }
    }
  }
}
