//@ ugl.bgcolor = 0x010101

/*
An Unconventional Weapon
========================

*/

import flash.geom.Point;
import vault.ds.Tuple;

class C {
  static public var black:UInt = 0x010101;
  static public var white:UInt = 0xFAFAFA;
  static public var yellow:UInt = 0xffdc3b;
  static public var purple:UInt = 0xff54b1;
  static public var cyan:UInt = 0xAA00FF;
  static public var blue:UInt = 0x00AAFF;
}

class LD32 extends Micro {
  var bg: BG;
  var player: Player;
  var counter: Float;
  var score: Int;
  public var speed: Float;
  static public function main() {
    new Sound("hook").vol(0.1).laser(1249);
    new Sound("grab").hit(1249);
    new Sound("hit").explosion(1238);

    // new Sound("connect").vol(0.1).powerup(1246);
    // new Sound("leave").vol(0.1).hit(1259);
    // new Sound("done").vol(0.1).powerup(1274);

    Micro.baseColor = C.white;
    new LD32("the name of the game is grab", "");
  }

  override public function begin() {
    speed = 1.5;
    counter = 3.5;
    score = 0;
    bg = new BG();
    player = new Player();
    new Minion(C.yellow, 10, 10);
    new Minion(C.cyan, 470, 10);
    new Minion(C.blue, 470, 470);
    new Minion(C.purple, 10, 470);

    var i = switch(Std.int(4*Math.random())) {
      case 0: C.yellow;
      case 1: C.cyan;
      case 2: C.blue;
      default: C.purple;
    };
    bg.change(i);
  }

  public function change(color: UInt) {
    // EATEN
    counter = 3.5;
    new Minion(Game.scene.bg.color);
    Game.shake(0.2);
    bg.change(color);
    speed *= 1.06;
    score += 1;
    new Score(score, false);
  }

  override public function final() {
    new Score(score, true);
    new EndGame(player.pos);
  }

  override public function update() {
    counter += Game.time;
    if (bg.color == C.cyan) {
    }
  }
}

class Player extends Entity {
  static var layer = 100;
  public var hook: Hook;
  public var stop: Bool = false;
  override public function begin() {
    pos.x = pos.y = 240;
    gfx.fill(C.black).circle(16, 16, 16);
    hook = new Hook(this);
    addHitBox(Circle(16,16,16));
  }

  function kill() {
    stop = true;
    new Sound("hit").play();
    clearHitBox();
    vel.x = vel.y = 0;
    Game.delay(0.2);
    Game.shake(0.5);
    Game.scene.endGame();
  }

  override public function update() {
    if (stop) return;
    var mv = new Vec2(0,0);
    if (hook.action == 0) {
      if (Game.key.left) mv.x = -1;
      if (Game.key.right) mv.x = 1;
      if (Game.key.up) mv.y = -1;
      if (Game.key.down) mv.y = 1;
      mv.normalize();
      mv.mul(1700);
      acc.add(mv);
      var drag = vel.copy();
      drag.mul(-5);
      acc.add(drag);
    } else {
      acc.length = vel.length = 0;
    }

    // if (pos.x < 0) pos.x += 480;
    // if (pos.x >= 480) pos.x -= 480;
    // if (pos.y < 0) pos.y += 480;
    // if (pos.y >= 480) pos.y -= 480;
    if (pos.x <= 10) { pos.x = 10; vel.x = Math.abs(vel.x); }
    if (pos.x >= 470) { pos.x = 470; vel.x = -Math.abs(vel.x); }
    if (pos.y <= 10) { pos.y = 10; vel.y = Math.abs(vel.y); }
    if (pos.y >= 470) { pos.y = 470; vel.y = -Math.abs(vel.y); }

    if (hook.action != 3) {
      var b: Bullet = hitGroup("Bullet");
      if (b != null) {
        kill();
        return;
      }
      var m: Minion = hitGroup("Minion");
      if (m != null && m.wait == 0) {
        kill();
        return;
      }
    }

  }
}

class Hook extends Entity {
  static var layer = 99;
  var player: Player;
  var arm: Float;
  var target: Minion = null;
  var maxarm: Float = 200;
  public var action: Int = 0;
  override public function begin() {
    player = cast args[0];
    arm = 0.0;
    action = 0;
    draw();
    addHitBox(Rect(0, -4, 20, 18));
  }

  function draw() {
    var x = 10;
    var y = 10;
    gfx.clear();
    // gfx.line(1, 0xFF0000).rect(0, 0, 20, 14).line(null);
    gfx.fill(C.black).circle(x, y, 3);
    gfx.fill(C.black).rect(x-2.5, y-10, 5, 10);
    var v1 = new Vec2(1,0);
    v1.angle = -Math.PI/6.0;
    var v1r = v1.normal();
    gfx.fill(C.black).mt(x + 2.5*v1r.x          , y + 2.5*v1r.y)
                     .lt(x + 2.5*v1r.x + 10*v1.x, y + 2.5*v1r.y + 10*v1.y)
                     .lt(x - 2.5*v1r.x + 10*v1.x, y - 2.5*v1r.y + 10*v1.y)
                     .lt(x - 2.5*v1r.x          , y - 2.5*v1r.y);
    v1.angle = Math.PI + Math.PI/6.0;
    v1r = v1.normal();
    gfx.fill(C.black).mt(x + 2.5*v1r.x          , y + 2.5*v1r.y)
                     .lt(x + 2.5*v1r.x + 10*v1.x, y + 2.5*v1r.y + 10*v1.y)
                     .lt(x - 2.5*v1r.x + 10*v1.x, y - 2.5*v1r.y + 10*v1.y)
                     .lt(x - 2.5*v1r.x          , y - 2.5*v1r.y);

    gfx.fill(C.black).rect(x-2.5, y,5,arm);
  }

  override public function update() {
    if (player.stop) return;
    if (action == 0) {
      var m = new Vec2(Game.mouse.x, Game.mouse.y);
      m.sub(player.pos);
      angle = m.angle + Math.PI/2;
      if (Game.mouse.button_pressed) {
        new Sound("hook").play();
        action = 1;
      }
    }
    else if (action == 1) {
      arm = Math.min(maxarm, arm + Game.time*500);
      draw();

      var m: Minion = hitGroup("Minion");
      if (m != null) {
        new Sound("grab").play();
        target = m;
        m.grabbed = true;
        action = 3;
        Game.delay(0.05);
        for (e in Game.get("Minion")) {
          var m:Minion = cast e;
          m.wait = 1.5/Game.scene.speed;
        }
      }

      if (arm == maxarm) {
        action = 2;
      }
    } else if (action == 2) {
      arm = Math.max(0, arm - Game.time*800);
      draw();
      if (arm == 0) {
        action = 0;
      }
    } else if (action == 3) {
      var oldarm = arm;
      arm = Math.max(0, arm - Game.time*800);
      var v = player.pos.distance(target.pos);
      v.normalize();
      v.length = (arm - oldarm)/2.0;
      target.pos.sub(v);
      player.pos.add(v);

      draw();
      if (arm == 0) {
        Game.scene.change(target.color);
        action = 0;
      }
    }

    pos.x = player.pos.x + (16+arm/2)*Math.cos(angle - Math.PI/2);
    pos.y = player.pos.y + (16+arm/2)*Math.sin(angle - Math.PI/2);
  }
}

class Bullet extends Entity {
  public var color: UInt;
  override public function begin() {
    color = args[0];
    gfx.fill(color).circle(6,6,6).fill(color).rect(0, 6, 12, 6);
    gfx.fill(C.white, 0.9).circle(4,5,1).circle(8,5,1);
    addHitBox(Circle(6,6,6));
  }

  override public function update() {
    if (color == C.purple) {
    } else if (color == C.cyan) {
    } else {
      if (pos.x < 0 || pos.x > 480 || pos.y < 0 || pos.y > 480) remove();
    }
  }
}

class Minion extends Entity {
  static var layer = 10;
  public var color:UInt;
  public var grabbed = false;
  var target: Vec2;
  var bullet: Bullet;
  var bulletAngle = 0.0;
  var bulletDirection = false;
  public var wait: Float;
  var lastAction = 0;
  override public function begin() {
    var p = Game.scene.player.pos;
    pos.x = p.x <= 240 ? 460 : 20;
    pos.y = p.y <= 240 ? 460 : 20;
    if (args[1]) {
      pos.x = args[1];
      pos.y = args[2];
    }

    color = args[0];
    gfx.fill(color).circle(10,10,10).fill(color).rect(0, 10, 20, 10);
    gfx.fill(C.white, 0.9).circle(7,8,2).circle(13,8,2);
    addHitBox(Rect(0, 0, 20, 20));

    target = pos.copy();
    wait = 1.5/Game.scene.speed;

    if (color == C.blue) {
      target.x = target.y = 240;
    }

  }

  override public function update() {
    wait = Math.max(0.0, wait - Game.time);
    if (color == Game.scene.bg.color) {
      this.remove();
      if (bullet != null) bullet.remove();
    }
    if (grabbed) {
      vel.x = vel.y = 0;
    } else {

      if (target.x < 0) target.x += 480;
      if (target.x >= 480) target.x -= 480;
      if (target.y < 0) target.y += 480;
      if (target.y >= 480) target.y -= 480;

      if (color == C.purple) {
        if (wait == 0 && (bullet == null || bullet.dead)) {
          bullet = new Bullet(color);
          bulletDirection = Math.random() < 0.5;
          bullet.pos = pos.copy();
        }

        target = Game.scene.player.pos.distance(pos);
        if (target.length < 128) {
          target.length = -128;
        } else {
          target.length = 128;
        }
        target.add(pos);

        var dt = target.distance(pos);
        dt.clamp(Game.scene.speed*50*Game.time);
        pos.add(dt);

        if (bullet != null) {
          bulletAngle += (bulletDirection ? 1 : -1)*Math.PI*Game.time*0.1*Game.scene.speed;
          var t = new Vec2(128, 0);
          t.angle = bulletAngle;
          t.add(pos);
          var d = t.distance(bullet.pos);
          d.clamp(Game.scene.speed*100*Game.time);
          bullet.pos.add(d);
        }
      } else if (color == C.cyan) {
        var dt = target.distance(pos);
        if (dt.length < 10) {
          if (bullet != null) bullet.remove();
          if (wait == 0) {
            bullet = new Bullet(color);
          }
          if (bullet != null)  {
            target = Game.scene.player.pos.distance(pos);
            bullet.angle = target.angle + Math.PI/2;
            target.length = 200;
            target.add(pos);
            bullet.pos = pos.copy();
          }
        } else {
          if (bullet != null) {
            var db = target.distance(bullet.pos);
            if (db.length > 5) {
              db.clamp(Game.scene.speed*100*Game.time);
              bullet.pos.add(db);
            } else {
              dt.clamp(Game.scene.speed*50*Game.time);
              pos.add(dt);
            }
          } else {
            dt.clamp(Game.scene.speed*50*Game.time);
            pos.add(dt);
          }
        }
      } else if (color == C.yellow) {
        var c = new Vec2(240, 240);
        c.sub(Game.scene.player.pos);
        c.length = 200;
        c.x += 240;
        c.y += 240;
        target = c;
        var dt = target.distance(pos);
        dt.clamp(Game.scene.speed*50*Game.time);
        pos.add(dt);

        if (dt.length < 10) {
          if (wait == 0 && (bullet == null || bullet.dead)) {
            bullet = new Bullet(color);
            bullet.pos = pos.copy();
            bullet.vel = Game.scene.player.pos.distance(pos);
            bullet.angle = bullet.vel.angle + Math.PI/2;
            bullet.vel.length = Game.scene.speed*100;
          }
        }
      } else if (color == C.blue) {
        if (lastAction != Game.scene.player.hook.action) {
          lastAction = Game.scene.player.hook.action;

          if (Game.scene.player.hook.action == 1) {
            var d = pos.distance(Game.scene.player.pos);
            d.rotate(Math.PI/2);
            d.length = Math.random() < 0.5 ? 50 : -50;
            target = pos.copy();
            target.add(d);
            if (bullet == null || bullet.dead) {
              bullet = new Bullet(color);
              bullet.pos = pos.copy();
              bullet.vel = Game.scene.player.pos.distance(pos);
              bullet.angle = bullet.vel.angle + Math.PI/2;
              bullet.vel.length = Game.scene.speed*100;
            }
          }
        }

        var dt = target.distance(pos);
        dt.clamp(Game.scene.speed*50*Game.time);
        pos.add(dt);
      }

      if (pos.y < 0) pos.x += 480;
      if (pos.x >= 480) pos.x -= 480;
      if (pos.y < 0) pos.y += 480;
      if (pos.y >= 480) pos.y -= 480;
    }
  }
}

class BG extends Entity {
  static var layer = 1;
  public var color: UInt;
  override public function begin() {
    pos.x = pos.y = 240;
  }

  public function change(color: UInt) {
    gfx.clear();
    this.color = color;
    gfx.fill(color).rect(0, 0, 480, 480);
  }

  override public function update() {
  }
}


class EndGame extends Entity {
  static var layer = 999;
  var start: Vec2;
  var stage: Int;
  var p1: Vec2;
  var p2: Vec2;
  var p3: Vec2;
  var p4: Vec2;
  override public function begin() {
    pos.x = pos.y = 240;
    start = args[0];
    stage = 0;
    p1 = start.copy(); p1.x -= 10; p1.y -= 10;
    p2 = start.copy(); p2.x += 10; p2.y -= 10;
    p3 = start.copy(); p3.x += 10; p3.y += 10;
    p4 = start.copy(); p4.x -= 10; p4.y += 10;
  }

  override public function update() {
    var speed = 5000*Game.time;
    if (stage == 0) {
      var target = new Vec2(0, 0);
      var d = target.distance(p1);
      d.clamp(speed);
      p1.add(d);
      if (d.length <= 0.0) {
        stage = 1;
      }
    } else if (stage == 1) {
      var target = new Vec2(0, 480);
      var d = target.distance(p4);
      d.clamp(speed);
      p4.add(d);
      if (d.length <= 0.0) {
        stage = 2;
      }
    } else if (stage == 2) {
      var target = new Vec2(480, 0);
      var d = target.distance(p2);
      d.clamp(speed);
      p2.add(d);
      if (d.length <= 0.0) {
        stage = 3;
      }
    } else if (stage == 3) {
      var target = new Vec2(480, 480);
      var d = target.distance(p3);
      d.clamp(speed);
      p3.add(d);
      if (d.length <= 0.0) {
        stage = 4;
      }
    } else if (stage == 4) {
      new Text().xy(240, 200).size(5).color(C.yellow).text("GAME OVER");
      new Text().text("the name of the game is grab").xy(240, 240).size(2).color(C.yellow);
      new Text().text("your score is " + Game.scene.score).xy(240, 320).size(3).color(C.yellow);
      stage = 5;
    }

    gfx.clear().size(480, 480);
    gfx.fill(C.black).mt(p1.x, p1.y).lt(p2.x, p2.y).lt(p3.x, p3.y).lt(p4.x, p4.y).fill();
  }
}
