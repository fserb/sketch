//@ ugl.bgcolor = 0xbf1b25

/*
TODO
- sound
*/

import vault.ugl.*;
import vault.EMath;
import vault.Vec2;
import vault.ugl.PixelArt.C;

class Asteroid extends Game {
  public var score = 0.0;
  var display: Text;

  public var realtime = 0.0;
  var totaltime = 0.0;
  var timeforball = 0.0;
  var wavecount = 1.0;
  var timeforenemy = 0.0;
  var fastforward = false;

  static public function main() {
    Game.debug = true;
    new Asteroid("Super Hot Asteroid", "");
  }

  override public function initialize() {
    Game.orderGroups(["Ball", "Enemy", "Particle", "Player", "Bullet", "Text"]);
  }

  override public function end() {
    fastforward = true;
    Game.one("Player").remove();
    holdback = 2.5;
    display.remove();
  }

  override public function begin() {
    new Player();
    score = 0.0;
    timeforball = 2.0;
    timeforenemy = 0.0;
    totaltime = 0.0;
    wavecount = 1.0;
    fastforward = false;
    display = new Text().color(0xFFFFFF).xy(10, 10).align(TOP_LEFT).size(2);
  }

  public function addShake(?t: Float = 0.4) {
    shaking = Math.max(shaking, t);
  }

  var shaking = 0.0;
  function shake() {
    shaking = Math.max(0.0, shaking - realtime);
    if (shaking <= 0) {
      Game.sprite.x = Game.sprite.y = 0;
      return;
    }

    Game.sprite.x = -5 + 10*Math.random();
    Game.sprite.y = -5 + 10*Math.random();
  }

  var fdisplay: Array<Text>;
  var count = 0.0;
  var flip = false;
  override public function final() {
    count = 0.0;
    flip = true;
    fdisplay = [];
  }

  override public function finalupdate() {
    realtime = Game.time;
    count = Math.max(0.0, count - Game.time);

    if (count <= 0) {
      for (f in fdisplay) f.remove();
      fdisplay = [];
      count += 1.0;
      flip = !flip;
      if (flip) {
        fdisplay.push(
          new Text().color(0xFFFFFF).xy(240, 240)
            .size(12).text(""+Std.int(score)));
      } else {
        fdisplay.push(new Text().color(0xFFFFFF).xy(240, 120).size(9).text("SUPER"));
        fdisplay.push(new Text().color(0xFFFFFF).xy(240, 240).size(9).text("HOT"));
        fdisplay.push(new Text().color(0xFFFFFF).xy(240, 360).size(9).text("ASTEROID"));
      }
    }
    shake();
  }

  override public function update() {
    realtime = Game.time;
    if (!(Game.key.up || Game.key.b1) && !fastforward) {
      Game.time /= 50.0;
    }
    totaltime += Game.time;

    timeforball -= Game.time;
    if (timeforball <= 0) {
      timeforball = 23.0;
      new Ball();
    }

    timeforenemy -= Game.time;
    if (timeforenemy <= 0) {
      for (i in 0...Std.int(wavecount)) {
        new Enemy();
      }
      timeforenemy += 5*Std.int(wavecount);
      wavecount *= 1.1;
    }

    var ents = Game.get("Enemy").length + Game.get("Ball").length;
    if (ents == 0) {
      timeforenemy = timeforball = 0;
    }

    if (Game.key.b2_pressed) {
      Game.one("Player").explode();
    }

    score += Game.time;
    display.text(""+Std.int(score));

    shake();
  }

  inline public function wrap(p: Vec2, s: Float) {
    if (p.x < -s/2) {
      p.x = 480 + s/2 - 1;
    } else if (p.x > 480 + s/2) {
      p.x = 0 - s/2 + 1;
    }

    if (p.y < -s/2) {
      p.y = 480 + s/2 - 1;
    } else if (p.y > 480 + s/2) {
      p.y = 0 - s/2 + 1;
    }
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

    var p = new Array<Vec2>();
    p.push(new Vec2(0, 0));
    p.push(new Vec2(24, 12));
    p.push(new Vec2(0, 24));
    addHitBox(Polygon(p));
  }

  public var reload = 0.0;
  override public function update() {
    if (Game.key.left) angle -= 1.5*Math.PI*Game.main.realtime;
    if (Game.key.right) angle += 1.5*Math.PI*Game.main.realtime;
    if (Game.key.up) {
      var v = new Vec2(200*Game.time, 0);
      v.rotate(angle);
      vel.add(v);
      vel.length = Math.min(200, vel.length);
    }

    reload = Math.max(0.0, reload - Game.time);
    if (Game.key.b1 && reload <= 0.0) {
      new Bullet(this);
      reload += 0.35;
    }
    Game.main.wrap(pos, 12);

    for (e in Game.get("Bullet")) {
      var b: Bullet = cast e;
      if (b.fromPlayer) continue;
      if (hit(b)) {
        explode();
        b.remove();
      }
    }
  }

  public function explode() {
    new Particle().color(0xFFFFFF)
      .count(Rand(70, 20)).xy(pos.x, pos.y)
      .size(Rand(3, 10)).speed(Rand(5, 25))
      .duration(Rand(2.0, 0.5));
    Game.main.addShake(0.5);
    Game.endGame();
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

    Game.main.wrap(pos, 0);

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
        Game.main.addShake();
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
    if (p != null && hit(p)) {
      p.explode();
    }

    Game.main.wrap(pos, size*2);
  }
}


class Enemy extends Entity {
  var target: Vec2;
  var reload = 1.5;

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

    var p = new Array<Vec2>();
    p.push(new Vec2(0, 0));
    p.push(new Vec2(24, 12));
    p.push(new Vec2(0, 24));
    addHitBox(Polygon(p));

    findTarget();
    angle = target.distance(pos).angle;
  }

  function findTarget() {
    target = new Vec2(480*Math.random(), 480*Math.random());
    var weight = 1.0 - Math.min(0.75, ticks/5.0);
    target.mul(weight*(1.0-weight));
    target.add(Game.one("Player").pos);
    target.mul(1.0/(1.0-weight));
  }

  override public function update() {
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
      vel.length = Math.min(200, vel.length);
    }

    var p: Player = Game.one("Player");
    if (p != null) {
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
    }

    Game.main.wrap(pos, 12);

    for (e in Game.get("Bullet")) {
      var b: Bullet = cast e;
      if (!b.fromPlayer) continue;
      if (hit(b)) {
        Game.main.addShake();
        remove();
        b.remove();
        Game.main.score += 10;
        new Text().xy(pos.x, pos.y).duration(1).move(0, -20).color(0xFFFFFF).text("+10");
        new Particle().color(0x000000)
          .count(Rand(40, 20)).xy(pos.x, pos.y)
          .size(Rand(3, 10)).speed(Rand(5, 25))
          .duration(Rand(1.0, 0.5));
      }
    }

    var p: Player = cast Game.one("Player");
    if (!dead && p != null && hit(p)) {
      remove();
      p.explode();
      new Particle().color(0x000000)
        .count(Rand(40, 20)).xy(pos.x, pos.y)
        .size(Rand(3, 10)).speed(Rand(5, 25))
        .duration(Rand(1.0, 0.5));
    }
  }
}
