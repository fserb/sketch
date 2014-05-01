//@ ugl.bgcolor = 0x8232cd

/*
- score
- add one shield
- explosions
- level transitions 
- mid area turrets
- less layers, more diversity
- feedback on Chunk heal

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
}

class Orbit extends Game {
  var level = 0;
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
    level = -1;
    // level = 3;
    nextLevel();
  }

  override public function end() {
    Game.one("Player").remove();
  }

  public function nextLevel() {
    for (g in [ "Bullet", "Enemy", "Chunk", "Level" ]) {
      for (e in Game.get(g)) {
        e.remove();
      }
    }
    new Level(++level);
  }
}

enum LevelData {  
  Layer(pattern: String, weight: String);
}

class Level extends Entity {
  static var DATA: Array<Array<LevelData>> = [ 
    [ Layer("11111111", "11111111") ],

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

  var layers: Array<Array<Chunk>>;
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
  public var clockwise = false;

  override public function begin() {
    gfx.fill(C.white).mt(10, 0).lt(20, 22).lt(10, 16).lt(0, 22); 
    addHitBox(Rect(0, 0, 20, 22));        
  }

  static var ANGSPEED = Math.PI/4.0;
  var bulletTime = 1.0;
  override public function update() {
    if (Game.key.b1_pressed || Game.mouse.button_pressed) {
      clockwise = !clockwise;  
    }

    if (!Game.key.b2) {
      if (clockwise) {
        angle -= ANGSPEED*Game.time;
      } else {
        angle += ANGSPEED*Game.time;
      }
    }

    radius = Math.max(200, radius - 10*Game.time/0.2);

    angle = (2*Math.PI + angle) % (2*Math.PI);
    pos.x = 240 + radius*Math.cos(angle + Math.PI/2.0);
    pos.y = 240 + radius*Math.sin(angle + Math.PI/2.0);

    bulletTime -= Game.time;
    if (bulletTime <= 0.0) {
      bulletTime += 0.5;
      new Bullet(this);
      new Sound("player bullet").play();
      radius += 10;
    }
  }
}

class Bullet extends Entity {
  static var layer = 101;

  override public function begin() {
    var p: Player = args[0];
    pos.x = p.pos.x;
    pos.y = p.pos.y;
    gfx.fill(C.white).mt(3, 0).lt(0, 10).lt(0, 12).lt(6, 12).lt(6, 10);
    angle = p.angle;
    vel.length = 300;
    vel.angle = p.angle - Math.PI/2;
    addHitBox(Rect(0, 0, 10, 12));    
  }

  override public function update() {
    if (pos.x < 0 || pos.y < 0 || pos.x > 480 || pos.y > 480) {
      remove();
    }

    if (hit(Game.one("Enemy"))) {
      remove();
      Game.one("Enemy").remove();
      Game.main.nextLevel();      
    }
  }
}

class Chunk extends Entity {
  static var layer = 50;
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

  var maxHealth: Float;
  var health: Float;
  var arc_begin: Float;
  var arc_end: Float;
  var radius: Float;

  override public function begin() {
    radius = args[0];
    var begin: Int = args[1];
    var size: Int = args[2];
    var d: Int = args[3];
    maxHealth = health = args[4];

    pos.x = pos.y = 0;
    rotationcenter = new Vec2(240, 240);
    alignment = TOPLEFT;

    var delta = Math.PI/d - Math.PI/96;
    arc_begin = 2*Math.PI*begin/d - delta;
    arc_end = 2*Math.PI*(begin + size - 1)/d + delta;
    draw();
  }

  function draw() {
    var r = (3 + 9*health/5.0)/2.0;
    gfx.clear().fill(vault.Utils.colorLerp(C.color, C.black, health/5.0))
      .arc(240, 240, radius - r, radius + r, arc_begin, arc_end).fill();
    clearHitBox();
    addHitBox(arcHitBox(radius - r, radius + r, arc_begin, arc_end));
  }

  override public function update() {
    // health = Math.min(maxHealth, health + Game.time/7.0);
    draw();
    for (b in Game.get("Bullet")) {
      if (hit(b)) {
        b.remove();
        health -= 1;
        draw();
        if (health <= 0.2) {
          remove();
        }
      }
    }
  }  
}

class Enemy extends Entity {
  static var layer = 60;

  var angvel = 0.0;
  var bulletDelay = 0.75;
  override public function begin() {
    pos.x = pos.y = 240;
    gfx
      .fill(C.color).rect(0, 0, 40, 40)
      .fill(C.black).circle(20, 20, 10)
      .mt(20, 0).lt(30, 20).lt(10, 20).fill(null);
    addHitBox(Circle(20, 20, 17));
    angle = Game.one("Player").angle + Math.PI;
    lastPos = new List<Float>();
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

    bulletTime -= Game.time;

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
    gfx.fill(0x000000).mt(3, 0).lt(0, 10).lt(0, 12).lt(6, 12).lt(6, 10);
    angle = p.angle;
    vel.length = 300;
    vel.angle = p.angle - Math.PI/2;
    addHitBox(Rect(0, 0, 10, 12));    
  }

  override public function update() {
    if (pos.x < 0 || pos.y < 0 || pos.x > 480 || pos.y > 480) {
      remove();
    }
    if (hit(Game.one("Player"))) {
      remove();
      Game.endGame();
    }

    var b = hitGroup("Bullet");
    if (b != null) {
      new Sound("bullet exp").play();
      b.remove();
      remove();
    }
  }
}
