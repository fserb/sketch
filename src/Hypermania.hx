//@ ugl.bgcolor = 0x04a2fc
//0x3b4964

/*
- pick a pattern
- level change
- x/ytime patterns
- poop/enemy colision
- score
- lives?
*/

import vault.ugl.*;
import flash.geom.Rectangle;
import vault.EMath;
import vault.Vec2;
import vault.ugl.PixelArt.C;

class Hypermania extends Game {
  var player: Player;
  public var energy: Float;

  static public function main() {
    Game.debug = true;
    new Hypermania("Hypermania", "");
  }

  override public function end() {
  }

  override public function begin() {
    new Bar();
    player = new Player();
    new Wave();
    energy = 100.0;
  }

  override public function final() {
  }

  override public function update() {
    energy -= Game.time*100.0/120.0;
  }
}

class Player extends Entity {
  public var bullet: Bullet = null;
  override public function begin() {
    art.size(3, 8, 12).obj([0xFFFFFF], "
...00...
..0000..
.000000.
.000000.
..0000..
...00...
00.00.00
00.00.00
00000000
00000000
00....00
00....00");
    pos.x = 240;
    pos.y = 480 - 80 - 18;
    addHitBox(Rect(0, 0, 24, 36));
  }

  override public function update() {
    if (Game.key.left) {
      pos.x = Math.max(36, pos.x - 200*Game.time);
    } else if (Game.key.right) {
      pos.x = Math.min(480 - 36, pos.x + 200*Game.time);
    }

    if (bullet == null) {
      if (Game.key.b1) {
        bullet = new Bullet();
        Game.main.energy -= Game.time*100.0/60.0;
      }
    } else {
      bullet.pos.x = Game.main.player.pos.x;
      bullet.pos.y -= 600*Game.time;
      if (bullet.pos.y < 9) {
        bullet.remove();
        bullet = null;
      }
    }
  }
}

class Bullet extends Entity {
  override public function begin() {
    art.cache(0).size(2).color(0xFFFFFF).circle(3, 3, 3);
    pos.y = 480-80-18 - 18;
    addHitBox(Rect(0, 0, 6, 18));
  }

  override public function update() {
    if (ticks > 0.07) {
      art.cache(1).size(3).color(0xFFFFFF).rect(0, 0, 2, 6);
    }
  }
}

enum StrategySpawn {
  Horizontal(w: Int, h: Int, dy: Float);
  Vertical(w: Int, h: Int, dx: Float);
}

typedef Strategy = {
  spawn: StrategySpawn,
  xmove: Int -> Float -> Float,
  ymove: Float -> Float,
  shooting: Float,
};

class Wave extends Entity {
  var all: Array<Enemy>;

  static var STRATS: Array<Strategy> = [
    { // megamania 1
      spawn: Horizontal(5, 3, 50),
      xmove: function(y, t) { return 200; },
      ymove: function(t) { return 0; },
      shooting: 0.1,
    },
    { // megamania 2
      spawn: Vertical(3, 6, 102),
      xmove: function(y, t) { if (t == 0) return 180*y;
        return (Std.int(t)%4 <= 1) ? 200 : -200; },
      ymove: function(t) { return (Std.int(t)%2 == 0) ? 50 : 0; },
      shooting: 0.1,
    },
    { // megamania 3
      spawn: Horizontal(5, 3, 50),
      xmove: function(y, t) { return 200; },
      ymove: function(t) { return 15*Math.sin(2*Math.PI*t/30.0); },
      shooting: 0.3,
    },
    { // megamania 4
      spawn: Vertical(3, 6, 102),
      xmove: function(y, t) { if (t == 0) return 130*y;
        return ((y+Std.int(t))%4 <= 1) ? 200 : -200; },
      ymove: function(t) { return (Std.int(t)%3 == 0) ? 50 : 0; },
      shooting: 0.3,
    },
    { // megamania 5
      spawn: Horizontal(5, 3, 50),
      xmove: function(y, t) { return 200; },
      ymove: function(t) { return 80*Math.sin(2*Math.PI*t/5.0); },
      shooting: 0.5,
    },
    { // megamania 6
      spawn: Vertical(3, 6, 102),
      xmove: function(y, t) { if (t == 0) return 240;
        var s = Std.int(1.5*t)%6;
        return (s == 0 || s == 4) ? 0 : (s == 1 || s == 3) ? -300 : 300; },
      ymove: function(t) { return (Std.int(t)%3 != 0) ? 50 : 0; },
      shooting: 0.5,
    },
    { // megamania 7
      spawn: Horizontal(5, 3, 50),
      xmove: function(y, t) { return 200; },
      ymove: function(t) { return 280*Math.sin(2*Math.PI*t/1.5); },
      shooting: 0.6,
    },
    { // megamania 8
      spawn: Vertical(3, 6, 102),
      xmove: function(y, t) { if (t == 0) return y*3211; return 0; },
      ymove: function(t) { return 250; },
      shooting: 0.0,
    },
  ];
  var strategy: Strategy;

  override public function begin() {
    strategy = STRATS[Std.int(Math.random()*STRATS.length)];
    spawn();
  }

  function spawn() {
    all = new Array<Enemy>();

    var pat = [];
    var cnt = 0;
    for (i in 0...(4*5)) pat.push(false);
    while (cnt < 10) {
      cnt = 0;
      for (y in 0...4) {
        for (x in 0... (Std.int(5/2)+1)) {
          if (Math.random() < 0.5) {
            pat[y*5 + x] = true;
            pat[y*5 + (4 - x)] = true;
            cnt += 1;
            if (x != 3) cnt += 1;
          }
        }
      }
    }

    switch (strategy.spawn) {
      case Horizontal(width, height, dy):
        var dx = (480 + 30)/width;
        for (y in 0...height) {
          for (x in 0...width) {
            var e = new Enemy(x, y,
              new Vec2(x*dx + (y%2)*(dx/2) - 496, 50.0 + y*dy),
              pat, strategy.shooting);
            all.push(e);
          }
        }
      case Vertical(width, height, dx):
      var dy = (400 + 30)/height;
        for (y in 0...height) {
          for (x in 0...width) {
            var e = new Enemy(x, y,
              new Vec2(x*dx + strategy.xmove(y, 0), -dy*y),
              pat, strategy.shooting);
            all.push(e);
          }
        }
    }
  }

  override public function update() {
    var xtick = ticks;
    var ytick = ticks;
    for (e in all) {
      e.pos.x += strategy.xmove(e.wy, xtick)*Game.time;
      e.pos.y += strategy.ymove(ytick)*Game.time;
      if (e.pos.x >= 480+15) { e.pos.x -= 480+30; }
      if (e.pos.x <= -15) { e.pos.x += 480+30; }
      if (e.pos.y >= 415) { e.pos.y -= 400+30; }
    }
  }
}

class Enemy extends Entity {
  public var wx: Int;
  public var wy: Int;
  public var shooting: Float;
  override public function begin() {
    art.size(6, 5, 4).color(0x000000);
    for (y in 0...4) {
      for (x in 0... 5) {
        if (args[3][x + y*5]) {
          art.dot(x, y);
        }
      }
    }

    wx = args[0];
    wy = args[1];
    pos.x = args[2].x;
    pos.y = args[2].y;
    shooting = args[4];
    addHitBox(Rect(0, 0, 33, 21));
  }

  override public function update() {
    if (pos.y > 0 && Math.random() < shooting*Game.time*0.5) {
      new EnemyBullet(pos.x + 2.5, pos.y + 12);
    }

    if (Game.main.player.bullet != null && hit(Game.main.player.bullet)) {
      Game.shake(0.1);
      remove();
      Game.main.player.bullet.remove();
      Game.main.player.bullet = null;
    }
  }
}

class EnemyBullet extends Entity {
  override public function begin() {
    art.cache(0).size(2).color(0x000000).circle(3, 3, 3);
    pos.x = args[0];
    pos.y = args[1];
    addHitBox(Rect(0, 0, 6, 18));
  }
  override public function update() {
    if (ticks > 0.07) {
      art.cache(1).size(3).color(0x000000).rect(0, 0, 2, 6);
    }
    pos.y += 500*Game.time;
    if (pos.y >= 420) {
      remove();
    }
  }
}

class Bar extends Entity {
  static var layer = 100;
  override public function begin() {
    alignment = TOPLEFT;
    pos.x = 0;
    pos.y = 410;
    gfx.fill(0x024972).rect(0, 0, 480, 70);
    new Energy();
  }
}


class Energy extends Entity {
  static var layer = 101;
  override public function begin() {
    alignment = TOPLEFT;
    pos.x = 40;
    pos.y = 430;
  }
  override public function update() {
    gfx.fill(0x011f30).rect(0, 0, 400, 10)
      .fill(0xe65205).rect(0, 0, 400*Game.main.energy/100, 10);
  }
}
