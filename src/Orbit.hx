//@ ugl.bgcolor = 0x8232cd

/*
- mid area turrets
- random levels
- less layers, more diversity
- better condition for new shield

*/

import vault.ugl.*;
import flash.geom.Point;
import flash.geom.Rectangle;
import vault.ds.Tuple;
import vault.EMath;
import vault.Vec2;
import vault.Ease;

import vault.algo.Voronoi;
import vault.algo.Voronoi.Edge;

class C {
  static public var white = 0xecebec;
  static public var black = 0x222222;
  static public var color = 0x8232cd;
  static public var halfwhite = vault.Utils.colorLerp(white, color, 0.75);
  static public var halfblack = vault.Utils.colorLerp(black, color, 0.75);
}

class Orbit extends Game {
  var level = 0;
  var score: Float;
  public var transition = false;

  static public function main() {
    Game.baseColor = 0xFFFFFF;
    new Orbit("Orbit", "");
    new Sound("player exp").explosion(1032);
    new Sound("player bullet").vol(0.15).laser(1350);
    new Sound("bullet exp").explosion(1002);
    new Sound("enemy bullet").vol(0.1).laser(1006);
  }
  override public function begin() {
    new Player();
    new Scorer();
    level = -1;
    score = 0.0;
    transition = true;
    // level = 3;
    nextLevel();
  }

  override public function end() {
    Game.one("Player").remove();
    new Score(score, true);
  }

  public function finishLevel() {
    Game.one("Enemy").explode();
    Game.delay(0.05);

    var lvl:Level = Game.one("Level");
    transition = true;
    new Timer().delay(0.75).run(function() {
      new Timer().every(0.05).run(function() {
        for (i in 0...lvl.layers.length) {
          for (c in lvl.layers[i]) {
            if (c.health > 0.0) {
              c.gotoHealth = 0.0;
              return true;
            }
          }
        }
        for (g in [ "Bullet", "Enemy", "Chunk", "Level" ]) {
          for (e in Game.get(g)) {
            e.remove();
          }
        }
        nextLevel();
        return false;
      });
      return false;
    });
  }

  public function nextLevel() {
    if (level > 0) {
      score += (level+1)*(level+1);
    }
    new Message("Level " + (level+1));
    var lvl = new Level(++level);
    new Timer().every(0.05).run(function() {
      for (i in 0...lvl.layers.length) {
        for (c in lvl.layers[i]) {
          if (c.health <= 0.0) {
            c.gotoHealth = c.maxHealth;
            return true;
          }
        }
      }
      transition = false;
      return false;
    });
  }

  override public function update() {
    score += Game.time/2.0;
  }
}

class Message extends Entity {
  static var layer = 500;
  var startx = 0.0;
  var targetx = 0.0;
  static var current_ticks = 5.0;
  var textwidth = 0.0;

  override public function begin() {
    var msg = args[0];
    if (current_ticks < 4.0) {
      remove();
      new Timer().delay(4.0 - current_ticks + 0.1).run(function() {
        new Message(msg);
        return true;
      });
      return;
    }
    current_ticks = 0.0;

    textwidth = (args[0].length+2)*12;
    gfx.fill(C.black).rect(0, 0, textwidth, 30).text(textwidth/2, 15, msg, C.white, 2);
    alignment = TOPLEFT;
    pos.x = startx = -textwidth;
    targetx = 0;
    pos.y = 15;
  }

  override public function update() {
    current_ticks = ticks;
    pos.x = startx + Math.min(1.0, Ease.quadIn(ticks/0.75))*(targetx-startx);

    if (ticks >= 3.0) {
      pos.x = targetx + Math.min(1.0, Ease.quadIn((ticks - 3.0)/0.75))*(startx-targetx);
    }
    if (ticks >= 4.0) {
      remove();
    }
  }
}

class Scorer extends Entity {
  static var layer = 501;
  var lastscore = -1;
  override public function begin() {
    pos.x = 400;
    pos.y = 480 - 30 - 15;
    alignment = TOPLEFT;
  }

  override public function update() {
    var score = Std.int(Game.main.score);
    if (score == lastscore) return;

    gfx.clear().fill(C.black).rect(0, 0, 80, 30).text(40, 15, ""+score, C.white, 2);
    new Score(score, false);

    var last50 = Std.int(lastscore/100);
    var cur50 = Std.int(score/100);

    if (last50 != cur50) {
      var pl: Player = Game.one("Player");
      if (!pl.shield) {
        pl.addShield();
        new Message("+shield");
      }

    }

    lastscore = score;
  }
}

enum LevelData {  
  Layer(pattern: String, weight: String);
}

class Level extends Entity {
  static var DATA: Array<Array<LevelData>> = [ 
    [ Layer("11111111", "22222222") ],

    [ Layer("1111", "2222"),
      Layer("11111111", "12121212"),
     ],

    [ Layer("1", "5"),
      Layer("111111", "333333"),
      Layer("121212", "535353"),
      ],

    [ Layer("111111111", "3333333333"),
      Layer("111", "555"),
      Layer("1111111", "15151515"),
      Layer("1111111", "51515151")
    ],

    [ Layer("131313", "151515"),
      Layer("11111", "12345"),
      Layer("111", "444"),
      Layer("515151", "515151"),
      Layer("111111111111", "333333333333") ],
  ];

  public var layers: Array<Array<Chunk>>;
  var dangle: Array<Float>;

  override public function begin() {
    var data = DATA[args[0]];

    layers = new Array<Array<Chunk>>();
    dangle = new Array<Float>();

    var radius = 40;
    for (layer in data) {
      var l = new Array<Chunk>();
      layers.push(l);
      dangle.push(0.0);
      switch(layer) {
        case Layer(pattern, weight):
          var total = 0;
          for (i in 0...pattern.length) {
            var c = Std.parseInt(pattern.charAt(i));
            total += c > 0 ? c : 1;
          }
          var d = 0;
          for (i in 0...pattern.length) {
            var c = Std.parseInt(pattern.charAt(i));
            var w = Std.parseInt(weight.charAt(i));
            if (c != 0) {
              var chk = new Chunk(radius, d, c, total, w);
              l.push(chk);
              d += c;
            } else {
              d++;
            }
        }
      }
      radius += 15;
      vault.Utils.shuffle(l);
    }

    picklayer = 12.0/dangle.length;
    new Enemy();
  }

  var picklayer = 0.0;
  override public function update() {
    picklayer -= Game.time;
    if (picklayer <= 0.0) {
      picklayer += 12.0/dangle.length;
      dangle[Std.int(Math.random()*dangle.length)] = 2*Math.PI*Math.random();
    }

    for (i in 0...layers.length) {
      var ang = layers[i][0].angle;
      if (ang == dangle[i]) continue;
      var maxda = 5*Game.time;
      var da = EMath.clamp(EMath.angledistance(ang, dangle[i]), -maxda, maxda);
      for (c in layers[i]) {
        c.angle -= da;
       } 
    }
  }
}

class Player extends Entity {
  static var layer = 70;

  var radius = 200.0;
  public var shield = true;
  public var clockwise = false;

  override public function begin() {
    draw();
    addHitBox(Rect(7, 5, 20, 22));        
  }

  function draw() {
    gfx.clear();
    gfx.fill(C.white).mt(17, 5).lt(27, 27).lt(17, 21).lt(7, 27).fill(null); 
    if (shield) {
      gfx.line(3, C.halfwhite).circle(17, 17, 17).line(null);
    }
  }

  public function addShield() {
    shield = true;
    draw();
  }

  public function removeShield() {
    shield = false;  
    draw();
  }

  static var ANGSPEED = Math.PI/4.0;
  var bulletTime = 1.0;
  override public function update() {
    if (Game.key.b1_pressed || Game.mouse.button_pressed) {
      clockwise = !clockwise;  
    }

    if (clockwise) {
      angle -= ANGSPEED*Game.time;
    } else {
      angle += ANGSPEED*Game.time;
    }

    if (Game.key.b2_pressed) {
      Game.main.finishLevel();
    }

    radius = Math.max(200, radius - 10*Game.time/0.2);

    angle = (2*Math.PI + angle) % (2*Math.PI);
    pos.x = 240 + radius*Math.cos(angle + Math.PI/2.0);
    pos.y = 240 + radius*Math.sin(angle + Math.PI/2.0);

    if (!Game.main.transition) {
      bulletTime -= Game.time;
    }
    if (bulletTime <= 0.0) {
      bulletTime += 0.5;
      var firepos = new Vec2(-2, -12);
      firepos.rotate(angle);
      firepos.add(pos);
      new Bullet(firepos, angle);
      new Sound("player bullet").play();
      radius += 20;
    }
  }
}

class Bullet extends Entity {
  static var layer = 101;
  public var removeIn = 0.0;

  override public function begin() {
    pos.x = args[0].x;
    pos.y = args[0].y;
    angle = args[1];
    vel.length = 300;
    vel.angle = angle - Math.PI/2;
    addHitBox(Rect(0, 0, 10, 12));    
    gfx.cache(0).fill(C.white).circle(6, 6, 6);
  }

  public function explode() {
    gfx.cache(2).fill(C.halfblack).circle(12, 12, 12);
    vel.x = vel.y = 0;
    removeIn = 0.05;
  }

  override public function update() {
    if (pos.x < 0 || pos.y < 0 || pos.x > 480 || pos.y > 480) {
      remove();
    }

    if (removeIn > 0) {
      removeIn -= Game.time;
      if (removeIn <= 0.0) {
        remove();
      }
      return;
    } 

    {
      if (ticks > 0.06) {
        gfx.cache(1).fill(C.white).mt(3, 0).lt(0, 10).lt(0, 12).lt(6, 12).lt(6, 10);
      }
    }

    if (hit(Game.one("Enemy"))) {
      explode();
      Game.main.finishLevel(); 
    }
  }
}

class Chunk extends Entity {
  static var layer = 9;

  function arc(arr: Array<Vec2>, x:Float, y:Float, r:Float, b:Float, e:Float) {
    var segments = Math.ceil(Math.abs(e-b)/(Math.PI/8));
    var theta = -(e-b)/segments;
    var angle = -b;
    var ctrlRadius = r/Math.cos(theta/2);
    arr.push(new Vec2(x+Math.cos(angle)*r, y+Math.sin(angle)*r));
    for (i in 0...segments) {
      angle += theta;
      var angleMid = angle-(theta/2);
      var cx = x+Math.cos(angleMid)*(ctrlRadius);
      var cy = y+Math.sin(angleMid)*(ctrlRadius);
      // calculate our end point
      var px = x+Math.cos(angle)*r;
      var py = y+Math.sin(angle)*r;
      // draw the circle segment
      arr.push(new Vec2(px, py));
    }
  }  

  function arcHitBox(r1: Float, r2: Float, begin: Float, end: Float): Entity.HitType {
    var arr = new Array<Vec2>();
    arc(arr, 240, 240, r1, begin, end);
    arc(arr, 240, 240, r2, end, begin);
    return Polygon(arr);
  }  

  public var maxHealth: Float;
  public var health: Float;
  public var gotoHealth: Float;

  var arc_begin: Float;
  var arc_end: Float;
  var radius: Float;

  override public function begin() {
    radius = args[0];
    var begin: Int = args[1];
    var size: Int = args[2];
    var d: Int = args[3];
    maxHealth = args[4];
    health = 0.0;
    gotoHealth = -1.0;

    pos.x = pos.y = 0;
    rotationcenter = new Vec2(240, 240);
    alignment = TOPLEFT;

    var delta = Math.PI/d - Math.PI/96;
    arc_begin = 2*Math.PI*begin/d - delta;
    arc_end = 2*Math.PI*(begin + size - 1)/d + delta;
  }

  public function draw() {
    var r = (3 + 9*health/5.0)/2.0;
    gfx.clear().fill(vault.Utils.colorLerp(C.color, C.black, health/5.0))
      .arc(240, 240, radius - r, radius + r, arc_begin, arc_end).fill();
    clearHitBox();
    addHitBox(arcHitBox(radius - r, radius + r, arc_begin, arc_end));
  }

  override public function update() {
    var p = new Vec2(0, 0);
    p.sub(pos);
    if (p.length != 0) {
      p.clamp(50*Game.time);
      pos.add(p);
    }

    if (gotoHealth >= 0.0) {
      var dh = EMath.clamp(gotoHealth - health, -Game.time/0.05, Game.time/0.2);
      health += dh;
      if (dh == 0) gotoHealth = -1.0;
      draw();
    }

    for (e in Game.get("Bullet")) {
      var b: Bullet = cast e;
      if (b.removeIn > 0) continue;
      if (hit(b)) {
        b.explode();

        health -= 1;
        draw();
        if (health <= 0.2) {
          Game.main.score += maxHealth;
          remove();
          var ang = b.angle - Math.PI/2;
          var diff = (arc_end - arc_begin);
          new Particle().color(vault.Utils.colorLerp(C.color, C.black, 1.0/5.0))
            .xy(240 + (-radius)*Math.cos(ang), 240 + (-radius)*Math.sin(ang))
            .size(6)
            .count(diff*100/(2*Math.PI))
            .duration(0.2)
            .direction(ang - diff, 2*diff)
            .speed(200);
          Game.shake(0.2);
        } else {
          var p = new Vec2(8/health, 0);
          p.angle = b.angle - Math.PI/2;
          pos.add(p);
          Game.shake(0.05);
        }
      }
    }
  }  
}

class Enemy extends Entity {
  static var layer = 8;

  var angvel = 0.0;
  var bulletDelay = 0.75;
  override public function begin() {
    pos.x = pos.y = 240;
    gfx
      .fill(C.color).rect(0, 0, 40, 40)
      .fill(C.black).circle(20, 20, 10)
      .fill(C.black).mt(20, 0).lt(30, 20).lt(10, 20).fill(null);
    addHitBox(Circle(20, 20, 17));
    angle = Game.one("Player").angle + Math.PI;
    lastPos = new List<Float>();
  }

  public function explode() {
    remove();
    new Particle().color(C.black).size(2, 10).xy(240, 240)
      .count(100)
      .duration(0.5)
      .direction(0, 2*Math.PI)
      .speed(50, 50);    
  }

  var bulletTime = 1.5;
  var order = 0;
  var lastPos: List<Float>;
  override public function update() {
    var pl: Player = Game.one("Player");
    if (pl == null) return;
    var pangle = (pl.angle + Math.PI);
    lastPos.add(pangle);

    while (lastPos.length > 60) {
      lastPos.pop();
    }

    var vel = 0.0;
    var vel_count = 0;
    var prev = lastPos.first();
    for (e in lastPos.iterator()) {
      vel += EMath.angledistance(prev, e);
      vel_count++;
      prev = e;
    }
    if (vel_count > 0) {
      vel = vel/vel_count;
    }
    vel /= Game.time;
    vel *= lastPos.length/60.0;
    vel *= 200/300;

    pangle -= vel;

    var normal = Math.sqrt(-2 * Math.log(Math.random())) * Math.cos(Math.random()*2*Math.PI);
    pangle += normal*Math.PI/32;
    pangle = (2*Math.PI + pangle) % (2*Math.PI);

    bulletDelay = Math.max(0.1, bulletDelay - 0.1*Game.time/30.0);

    var da = EMath.angledistance(angle, pangle);
    var a = function(x:Float) { return Std.int(x*180/Math.PI); };
    if (da > 0) {
      angvel -= 10*Game.time;
    } else if (da < 0) {
      angvel += 10*Game.time;
    }
    angvel *= 0.9;
    angle += angvel*Game.time;

    if (!Game.main.transition) {
      bulletTime -= Game.time;
    }

    if (bulletTime <= 0.0) {
      bulletTime = bulletDelay;
      new EnemyBullet(this);
      new Sound("enemy bullet").play();
    }    
  }
}

class EnemyBullet extends Entity {
  static var layer = 100;

  override public function begin() {
    var p: Enemy = args[0];
    pos.x = pos.y = 240;

    gfx.cache(0).fill(0x000000).circle(6, 6, 6);

    angle = p.angle;
    vel.length = 300;
    vel.angle = p.angle - Math.PI/2;
    addHitBox(Rect(0, 0, 10, 12));    
  }

  override public function update() {
    if (pos.x < 0 || pos.y < 0 || pos.x > 480 || pos.y > 480) {
      remove();
    }

    if (ticks > 0.06) {
      gfx.cache(1).fill(0x000000).mt(3, 0).lt(0, 10).lt(0, 12).lt(6, 12).lt(6, 10);
    }


    var pl: Player = Game.one("Player");
    if (hit(pl)) {
      remove();
      Game.flash(C.white);
      if (pl.shield) {
        pl.removeShield();
      } else {
        Game.endGame();
      }
    }

    var b = hitGroup("Bullet");
    if (b != null) {
      new Sound("bullet exp").play();
      b.remove();
      remove();
    }
  }
}
