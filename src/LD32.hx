//@ ugl.bgcolor = 0xffc704

/*
An Unconventional Weapon
========================



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
  static public var purple = 0x8c07a8;
  static public var cyan = 0x03939a;
}

class LD32 extends Micro {
  static public function main() {
    Micro.baseColor = C.black;
    new LD32("This game is called Grab", "");
  }  

  override public function begin() {
    new Player(); 
    new Minion();
  }
}

class Player extends Entity {
  static var layer = 100;
  var hook: Hook;
  override public function begin() {
    pos.x = pos.y = 240;
    gfx.fill(C.black).circle(16, 16, 16);
    hook = new Hook(this);
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
      drag.mul(-10);
      acc.add(drag);
    } else {
      acc.length = vel.length = 0;
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
    addHitBox(Rect(0, 0, 20, 14));
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
      }

      if (arm == maxarm) {
        action = 2;
      }
    } else if (action == 2) {
      arm = Math.max(0, arm - Game.time*900);
      draw();
      if (arm == 0) {
        action = 0;
      }
    } else if (action == 3) {
      var oldarm = arm;
      arm = Math.max(0, arm - Game.time*900);
      var v = player.pos.distance(target.pos);
      v.normalize();
      v.length = (arm - oldarm)/2.0;
      target.pos.sub(v);
      player.pos.add(v);

      draw();
      if (arm == 0) {
        // EATEN
        action = 0;
      }
    }

    pos.x = player.pos.x + (16+arm/2)*Math.cos(angle - Math.PI/2);
    pos.y = player.pos.y + (16+arm/2)*Math.sin(angle - Math.PI/2);
  }
}

class Minion extends Entity {
  static var layer = 10;
  public var type = 1;
  public var grabbed = false;
  override public function begin() {
    pos.x = 100;
    pos.y = 100;
    type = 2;
    var color = switch(type) {
      case 1: C.purple;
      case 2: C.cyan;
      case 3: C.yellow;
      default: C.black;
    };

    gfx.fill(color).circle(10,10,10).fill(color).rect(0, 10, 20, 10);
    gfx.fill(C.white, 0.9).circle(7,8,2).circle(13,8,2);
    // gfx.fill(C.black, 1.0).circle(7,8,1).circle(13,8,1);
    addHitBox(Rect(0, 0, 20, 20));
  }

  override public function update() {

  }
}
