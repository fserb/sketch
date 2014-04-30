//@ ugl.bgcolor = 0x8232cd

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
  static public var black = 0x161616;
  static public var color = 0x8232cd;

}

class Orbit extends Game {
  var level = 0;
  static public function main() {
    Game.baseColor = 0xFFFFFF;
    new Orbit("Orbit", "");
  }
  override public function begin() {
    new Player();
    level = -1;
    nextLevel();
  }

  override public function end() {
    Game.one("Player").remove();
  }

  public function nextLevel() {
    for (g in [ "Bullet", "EnemyBullet", "Chunk", "Level" ]) {
      for (e in Game.get(g)) {
        e.remove();
      }
    }
    new Level(++level);
  }
}

enum LevelData {  
  Layer(radius: Float, pattern: String, weight: String);
}

class Level extends Entity {
  static var DATA: Array<Array<LevelData>> = [ 
    [ Layer(40, "11111111", "11111111") ],

    [ Layer(40, "1111", "2222"),
      Layer(55, "11111111", "12121212"),
     ],

    [ Layer(40, "1", "5"),
      Layer(55, "111111", "333333"),
      Layer(70, "121212", "535353"),
      ],
  ];

  var layers: Array<Array<Chunk>>;
  var dangle: Array<Float>;

  override public function begin() {
    var data = DATA[args[0]];

    layers = new Array<Array<Chunk>>();
    dangle = new Array<Float>();

    for (layer in data) {
      var l = new Array<Chunk>();
      layers.push(l);
      dangle.push(0.0);
      switch(layer) {
        case Layer(radius, pattern, weight):
          var total = pattern.length;
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
    }
    picklayer = 5.0/dangle.length;
    new Enemy();
  }

  var picklayer = 0.0;
  override public function update() {
    picklayer -= Game.time;
    if (picklayer <= 0.0) {
      picklayer += 5.0/dangle.length;
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
  var radius = 200.0;
  public var clockwise = false;

  override public function begin() {
    gfx.fill(C.white).mt(10, 0).lt(20, 22).lt(10, 16).lt(0, 22); 
    addHitBox(Rect(0, 0, 20, 22));        
  }

  static var ANGSPEED = Math.PI/4.0;
  var bulletTime = 1.0;
  override public function update() {
    if (Game.key.b1_pressed) {
      clockwise = !clockwise;  
    }

    if (clockwise) {
      angle -= ANGSPEED*Game.time;
    } else {
      angle += ANGSPEED*Game.time;
    }

    radius = Math.max(200, radius - 10*Game.time/0.2);

    angle = (2*Math.PI + angle) % (2*Math.PI);
    pos.x = 240 + radius*Math.cos(angle + Math.PI/2.0);
    pos.y = 240 + radius*Math.sin(angle + Math.PI/2.0);

    bulletTime -= Game.time;
    if (bulletTime <= 0.0) {
      bulletTime += 0.75;
      new Bullet(this);
      radius += 10;
    }
  }
}

class Bullet extends Entity {
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

  var health: Int;
  var arc_begin: Float;
  var arc_end: Float;
  var radius: Float;

  override public function begin() {
    radius = args[0];
    var begin: Int = args[1];
    var size: Int = args[2];
    var d: Int = args[3];
    health = args[4];

    pos.x = pos.y = 0;
    rotationcenter = new Vec2(240, 240);
    alignment = TOPLEFT;

    var delta = Math.PI/d - Math.PI/96;
    arc_begin = 2*Math.PI*begin/d - delta;
    arc_end = 2*Math.PI*(begin + size - 1)/d + delta;
    draw();
  }

  function draw() {
    var r = (5 + 10*health/5.0)/2.0;
    gfx.clear().fill(vault.Utils.colorLerp(C.color, C.black, health/5.0))
      .arc(240, 240, radius - r, radius + r, arc_begin, arc_end).fill();
    clearHitBox();
    addHitBox(arcHitBox(radius - r, radius + r, arc_begin, arc_end));
  }

  override public function update() {
    for (b in Game.get("Bullet")) {
      if (hit(b)) {
        b.remove();
        health -= 1;
        draw();
        if (health <= 0) {
          remove();
        }
      }
    }
  }  
}

class Enemy extends Entity {
  var angvel = 0.0;
  override public function begin() {
    pos.x = pos.y = 240;
    gfx
      .fill(C.color).rect(0, 0, 40, 40)
      .fill(C.black).circle(20, 20, 10)
      .mt(20, 0).lt(30, 20).lt(10, 20).fill(null);
    addHitBox(Circle(20, 20, 17));
    angle = Game.one("Player").angle + Math.PI;
  }

  var bulletTime = 1.5;
  var order = 0;
  static var BULLETDELAY = 0.3;
  override public function update() {
    var pl: Player = Game.one("Player");
    if (pl == null) return;
    var pangle = (pl.angle + Math.PI);

    if (order == 1) {
      pangle += Math.PI/5;
    } else if (order == 3) {
      pangle -= Math.PI/5;
    }
    pangle = (2*Math.PI + pangle) % (2*Math.PI);

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

     if (Math.abs(da) <= Math.PI/32 || bulletTime < -BULLETDELAY) {
      if (bulletTime <= 0.0) {
        if (bulletTime >= -BULLETDELAY) {
          order = (order+1)%4;
        }
        bulletTime = BULLETDELAY;
        new EnemyBullet(this);
      }    
    }
  }
}

class EnemyBullet extends Entity {
  override public function begin() {
    var p: Enemy = args[0];
    pos.x = pos.y = 240;
    gfx.fill(C.black).mt(3, 0).lt(0, 10).lt(0, 12).lt(6, 12).lt(6, 10);
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
      b.remove();
      remove();
    }
  }
}
