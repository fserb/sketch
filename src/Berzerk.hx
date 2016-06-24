//@ ugl.bgcolor = 0xff3155

import vault.ugl.*;
import vault.EMath;
import vault.geom.Vec2;

class Berzerk extends Micro {
  public var nextScoreBox = 1;
  static public function main() {
    new Berzerk("Berzerk", "");
  }

  override public function end() {
  }

  override public function begin() {
    new Player();

    newEnemy();
    newEnemy();
    newEnemy();
  }

  public function newEnemy() {
    var r = Math.random();
    if (r < 0.5) new EnemyTurret();
    else new EnemyChaser();
  }

  override public function update() {
  }
}

class Player extends Entity {
  var reload = 0.0;
  override public function begin() {
    gfx.fill(0xFFFFFF).circle(11,11,11);
    pos.x = pos.y = 50;
    addHitBox(Circle(11,11,11));
  }

  override public function update() {
    vel.x = vel.y = 0;
    reload = Math.max(0.0, reload - Game.time);
    if (reload > 0.0) return;

    if (Game.key.left) vel.x = -1;
    if (Game.key.right) vel.x = 1;
    if (Game.key.up) vel.y = -1;
    if (Game.key.down) vel.y = 1;
    if (Game.key.b1) {
      new Bullet(this, 0xFFFFFF);
      reload = 0.3;
    }
    vel.normalize();
    vel.mul(120);
  }
}

class Bullet extends Entity {
  public var targetvel = 0.0;
  public var owner: Entity;
  override public function begin() {
    owner = args[0];
    pos = owner.pos.copy();
    vel = owner.vel.copy();
    vel.length = 100;
    targetvel = 400;
    angle = vel.angle;

    gfx.fill(args[1]).rect(0,0, 20, 6);
    addHitBox(Rect(0,0,20,6));

    if (vel.length == 0) remove();
  }

  override public function update() {
    vel.length = Math.min(targetvel, vel.length + 400*Game.time);
  }
}

class EnemyTurret extends Entity {
  var bullettime = 2.0;
  override public function begin() {
    addHitBox(Circle(20,20,12));
    gfx.size(40,40).fill(0x000000).circle(20, 20, 12).fill(0x000000).rect(20, 16, 17, 8);
    pos.x = 40 + Math.random()*400;
    pos.y = 40 + Math.random()*400;
  }

  override public function update() {
    var p: Player = Game.one("Player");
    var target = p.pos.copy();
    target.sub(pos);
    var ttb = target.length / (400 - 150);
    var sf = p.vel.copy();
    sf.mul(ttb);
    target.add(sf);
    var da = EMath.angledistance(angle, target.angle + Math.PI);
    da = EMath.clamp(da, -Game.time*Math.PI/2, Game.time*Math.PI/2);
    angle += da;

    bullettime = Math.max(0.0, bullettime - Game.time);
    if (bullettime <= 0.0) {
      bullettime = 3.0;
      var b = new Bullet(this, 0x000000);
      b.vel.angle = b.angle = angle;
    }

    var b: Bullet = hitGroup("Bullet");
    if (b != null && b.owner != this) {
      b.remove();
      die();
    }
  }

  function die() {
    remove();
    new ScoreBox(this);
    Game.scene.newEnemy();
  }
}

class EnemyChaser extends Entity {
  var bullettime = 2.0;
  override public function begin() {
    addHitBox(Rect(0,0,21,21));
    art.size(3,7,7).obj([0x00000], "
.00000.
0000000
0.000.0
0000000
0000000
0.0.0.0
0.0.0.0");
    pos.x = 40 + Math.random()*400;
    pos.y = 40 + Math.random()*400;
  }

  override public function update() {
    var p: Player = Game.one("Player");
    var target = p.pos.copy();
    target.sub(pos);
    var ttb = target.length / (400 - 150);
    var sf = p.vel.copy();
    sf.mul(ttb);
    target.add(sf);
    var da = EMath.angledistance(vel.angle, target.angle + Math.PI);
    da = EMath.clamp(da, -Game.time*Math.PI, Game.time*Math.PI);

    vel.length = 80;
    vel.angle += da;



    var b: Bullet = hitGroup("Bullet");
    if (b != null && b.owner != this) {
      b.remove();
      remove();
      new ScoreBox(this);
      Game.scene.newEnemy();
    }

    var et = hitGroup("EnemyTurret");
    if (et != null) {
      et.remove();
      remove();
      new ScoreBox(this);
      Game.scene.newEnemy();
    }

    var ec = hitGroup("EnemyChaser");
    if (ec != null) {
      ec.remove();
      remove();
      new ScoreBox(this);
      Game.scene.newEnemy();
    }
  }
}

class ScoreBox extends Entity {
  var scorebox: Int;
  override public function begin() {
    var o: Entity = args[0];
    scorebox = Game.scene.nextScoreBox;
    pos = o.pos.copy();
    art.size(3, 7, 7).color(0x000000).text(3.5, 3.5, ""+scorebox, 2);
    addHitBox(Rect(0,0,21,21));
  }

  override public function update() {
    if (hitGroup("Player")) {
      remove();
      Game.scene.nextScoreBox = Math.max(scorebox+1, Game.scene.nextScoreBox);
    }
  }
}
