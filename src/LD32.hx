//@ ugl.bgcolor = 0x010101

/*
An Unconventional Weapon
========================

- wall that you can use as shield
- sounds

*/

import vault.ugl.*;
import flash.geom.Point;
import flash.geom.Rectangle;
import vault.ds.Tuple;
import vault.EMath;
import vault.Vec2;
import vault.Ease;

class C {
  static public var black = 0x010101;
  static public var white = 0xFAFAFA;
  static public var yellow = 0xffc704;
  static public var purple = 0xd541f6;
  static public var cyan = 0x3eb3b9;
  static public var blue = 0x5167ef;
}

class LD32 extends Micro {
  var bg: BG;
  var player: Player;
  var counter: Float;
  public var speed: Float;
  static public function main() {
    Micro.baseColor = C.black;
    new LD32("This game is called Grab", "");
  }  

  override public function begin() {
    speed = 1.5;
    counter = 3.5;
    bg = new BG();
    player = new Player(); 
    new Minion(C.yellow);
    new Minion(C.cyan);
    new Minion(C.blue);
    bg.change(C.purple);
  }

  public function change(color: UInt) {
    // EATEN
    counter = 3.5;
    new Minion(Game.scene.bg.color);
    Game.shake(0.2);
    bg.change(color);
    speed *= 1.08;
    trace(speed);
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
  override public function begin() {
    pos.x = pos.y = 240;
    gfx.fill(C.black).circle(16, 16, 16);
    hook = new Hook(this);
    addHitBox(Circle(16,16,16));
  }

  function kill() {
    remove();
    Game.scene.endGame();
  }

  override public function update() {
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
      }
      var m: Minion = hitGroup("Minion");
      if (m != null && m.wait == 0) {
        kill();
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
    if (action == 0) {
      var m = new Vec2(Game.mouse.x, Game.mouse.y);
      m.sub(player.pos);
      angle = m.angle + Math.PI/2;
      if (Game.mouse.button_pressed) {
        action = 1;
      }
    }
    else if (action == 1) {
      arm = Math.min(maxarm, arm + Game.time*500);
      draw();

      var m: Minion = hitGroup("Minion");
      if (m != null) {
        target = m;
        m.grabbed = true;
        action = 3;
        for (e in Game.get("Minion")) {
          var m:Minion = cast e;
          m.wait = Game.scene.speed*1.0;
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
