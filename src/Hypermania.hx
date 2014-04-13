//@ ugl.bgcolor = 0x04a2fc

/*
- sound
- enemies shoot when you are under them
- make it harder to shoot enemies
- ticker
*/

import vault.ugl.*;
import flash.geom.Rectangle;
import vault.EMath;
import vault.Vec2;
import vault.ugl.PixelArt.C;

class Hypermania extends Game {
  public var player: Player;
  public var score: Float;
  public var energy: Float;
  public var bar: Bar;
  var wave: Wave;
  var waveCount: Int;

  static public function main() {
    Game.debug = true;
    new Hypermania("Hypermania", "");
  }

  override public function end() {
    player = null;
  }

  override public function begin() {
    bar = new Bar();
    player = new Player();
    energy = 100.0;
    wave = null;
    waveCount = 0;
    score = 0.0;
    beginLevel();
  }

  function beginLevel() {
    if (energy <= 0) energy = 1;
    new Timer().run(function() {
      energy = Math.min(100, energy + Game.time*100/1.0);
      if (wave != null) {
        wave.reset();
      }
      return energy < 100;
    }).run(function() {
      if (wave == null || wave.dead) {
        wave = new Wave();
      }
      wave.reset();
      return false;
    });
  }

  override public function final() {
    var s1 = new Text().size(4).color(0xFFFFFF).xy(240, 100).text("game over");

    var s2 = new Text().size(6).color(0xFFFFFF).xy(240, 200).text("" + Std.int(score));

    var str = waveCount +" waves completed";
    if (waveCount == 0) str = "you'll get better";
    else if (waveCount == 1) str = "one wave done";

    var s3 = new Text().size(3).color(0xFFFFFF).xy(240, 300).text(str);
  }

  function nextLevel() {
    if (wave == null) return;
    waveCount += 1;
    wave = null;
    new Timer().run(function() {
      var oe = energy;
      energy = Math.max(1, energy - Game.time*100/2.0);
      bar.addScore(waveCount*10*(oe - energy));
      if (energy > 1) return true;
      beginLevel();
      return false;
    });
  }

  override public function update() {
    if (wave == null) return;

    energy -= Game.time*100.0/75.0;

    if (energy <= 0) {
      player.explode();
    }

    if (Game.key.b2_pressed) {
      wave.remove();
      for (e in Game.get("Enemy")) {
        e.remove();
      }
      nextLevel();
    }
  }
}

class Player extends Entity {
  public var bullet: Bullet = null;
  public var combo: Int = 0;
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

  public function explode() {
    if (bullet != null) bullet.remove();
    remove();
    new Particle().xy(pos.x, pos.y).color(0xFFFFFF)
      .count(Const(80)).size(Const(6)).speed(Rand(20, 50)).duration(Const(1.5));
    Game.shake(1.0);
    Game.endGame();
  }

  override public function update() {
    pos.y = Math.max(480 - 80 - 18, pos.y - 100*Game.time);

    if (bullet == null) {
      if (Game.key.b1) {
        bullet = new Bullet();
        bullet.pos.x = Game.main.player.pos.x;
        new Light(bullet.pos);
        Game.main.energy -= 100.0/100.0;
        pos.y = 480 - 80;
      }
    } else {
      bullet.pos.x = Game.main.player.pos.x;
      bullet.pos.y -= 500*Game.time;
      if (bullet.pos.y < -9) {
        bullet.explode(false);
      }
    }
    var speed = 200;
    if (Game.key.left) {
      pos.x = Math.max(18, pos.x - speed*Game.time);
    } else if (Game.key.right) {
      pos.x = Math.min(480 - 18, pos.x + speed*Game.time);
    }
  }
}

class Light extends Entity {
  static var layer = 50;
  override public function begin() {
    gfx.fill(0xFFFFCC).circle(12, 12, 12);
    pos.x = args[0].x;
    pos.y = args[0].y;
  }
  override public function update() {
    remove();
  }
}

class Bullet extends Entity {
  var oy = 0.0;
  override public function begin() {
    oy = pos.y = 480 - 80 - 18 - 18;
    art.size(3).color(0xFFFFFF).rect(0, 0, 2, 6);
    addHitBox(Rect(0, 0, 6, 18));
  }

  public function explode(hit: Bool) {
    if (hit) {
      Game.main.player.combo += 1;
    } else {
      Game.main.player.combo = 0;
    }
    if (Game.main.player.combo > 1) {
      new Text().xy(pos.x, pos.y).move(0, -50).duration(0.5)
        .size(2).color(0xb23f04).text("x" + Game.main.player.combo);
    }
    Game.main.player.bullet = null;
    remove();
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
  public var all: List<Enemy>;
  var horizontal: Bool;
  var ticker: Float -> Int;
  static var TIMESTRATS: Array<Float -> Int> = [
    function(t) { return 0; },
    function(t) {
      if (Std.int(t)%2 == 0) return 0;
      return 10;
    },
    function(t) {
      var xx = Std.int(t) % 12;
      if (xx < 3) return 0;
      if (xx < 6) return 15;
      if (xx < 9) return 5;
      return 20;
    },
    function(t) {
      return 8 - Std.int(10*Math.cos(t*2*Math.PI/10.0));
    },
  ];

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
      ymove: function(t) { return 200; },
      shooting: 0.0,
    },
  ];
  var strategy: Strategy;

  override public function begin() {
    var wave = Game.main.waveCount;

    var s = wave % STRATS.length;
    var t = Std.int(wave / STRATS.length) % TIMESTRATS.length;

    strategy = STRATS[s];
    ticker = TIMESTRATS[t];
    spawn();
  }

  function spawn() {
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

    all = new List<Enemy>();
    switch (strategy.spawn) {
      case Horizontal(width, height, dy):
        horizontal = true;
        var dx = (480 + 30)/width;
        for (y in 0...height) {
          for (x in 0...width) {
            var e = new Enemy(x, y,
              new Vec2(x*dx + (y%2)*(dx/2) - 496, 50.0 + y*dy),
              pat, this);
            all.add(e);
          }
        }
      case Vertical(width, height, dx):
        horizontal = false;
        var dy = (400 + 30)/height;
        for (y in 0...height) {
          for (x in 0...width) {
            var e = new Enemy(x, y,
              new Vec2(15 + x*dx + strategy.xmove(y, 0), -dy*y),
              pat, this);
            all.add(e);
          }
        }
    }
  }

  public function reset() {
    switch (strategy.spawn) {
      case Horizontal(_, _, _):
       var maxx = 0.0;
        for (e in all) {
          maxx = Math.max(maxx, e.pos.x);
        }
        if (maxx > 0) {
          maxx += 100;
          for (e in all) {
            e.pos.x -= maxx;
          }
        }
      case Vertical(_, _, _):
        var maxy = 0.0;
        for (e in all) {
          maxy = Math.max(maxy, e.pos.y);
        }
        if (maxy > 0) {
          maxy += 30;
          for (e in all) {
            e.pos.y -= maxy;
          }
        }
    }
  }


  override public function update() {
    var shoot = false;
    if (Math.random() < strategy.shooting*Game.time*2) {
      shoot = true;
    }

    var shooter: Enemy = null;
    var cnt = 0;
    for (e in all) {
      for (steps in 0...(10 + ticker(ticks))) {
        e.pos.x += strategy.xmove(e.wy, ticks + steps*Game.time/10.0)*Game.time/10.0;
        e.pos.y += strategy.ymove(ticks + steps*Game.time/10.0)*Game.time/10.0;
      }
      if (e.pos.x >= 480+15) { e.pos.x -= 480+30; }
      if (!horizontal && e.pos.x <= -15) { e.pos.x += 480+30; }
      if (!horizontal && e.pos.y >= 415) { e.pos.y -= 400+30; }

      if (e.pos.y > 0 && shoot) {
        cnt += 1;
        if (shooter == null || Math.random() < 1.0/cnt) {
          shooter = e;
        }
      }
    }
    ticks += ticker(ticks)*Game.time/10.0;
    if (shooter != null) {
      shooter.shoot();
    }

    if (all.length == 0) {
      remove();
      Game.main.nextLevel();
    }
  }
}

class Enemy extends Entity {
  public var wx: Int;
  public var wy: Int;
  public var wave: Wave;
  var dotcount = 0;
  override public function begin() {
    draw();
    wx = args[0];
    wy = args[1];
    pos.x = args[2].x;
    pos.y = args[2].y;
    wave = args[4];
    addHitBox(Rect(0, 0, 30, 24));
  }

  function draw(?c: Int = 0x000000) {
    art.size(6, 5, 4).color(c);
    for (y in 0...4) {
      for (x in 0... 5) {
        if (args[3][x + y*5]) {
          art.dot(x, y);
          dotcount += 1;
        }
      }
    }
  }

  public function shoot() {
    new EnemyBullet(pos.x + 2.5, pos.y + 12);
  }

  override public function update() {
    if (hit(Game.main.player)) {
      Game.main.player.explode();
    }

    if (Game.main.player != null && hit(Game.main.player.bullet)) {
      Game.shake(0.2);
      draw(0xFFFFFF);
      Game.delay(0.01);
      new Timer().delay(0.1).run(function() {
        remove();
        wave.all.remove(this);
        new Particle().xy(pos.x, pos.y).color(0xFFFFFF)
          .spread(Const(5))
          .count(Const(dotcount)).size(Const(6)).speed(Rand(20, 50)).duration(Const(0.5));
        return false;
      });
      Game.main.player.bullet.explode(true);
      Game.main.bar.addScore(10*(Game.main.waveCount+1)*Game.main.player.combo);
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
    if (Game.main.player != null && hit(Game.main.player.bullet)) {
      Game.shake(0.1);
      Game.main.player.bullet.explode(true);
      art.cache(0).size(2).color(0xFFFFFF).circle(3, 3, 3);
      new Timer().delay(0.1).run(function() {
        remove();
        return false;
      });
      return;
    }

    if (hit(Game.main.player)) {
      Game.main.player.explode();
    }

    if (ticks > 0.07) {
      art.cache(1).size(3).color(0x000000).rect(0, 0, 2, 6);
    }
    pos.y += 400*Game.time;
    if (pos.y >= 420) {
      remove();
    }
  }
}

class Bar extends Entity {
  static var layer = 100;
  var displayScore: Text;

  override public function begin() {
    alignment = TOPLEFT;
    pos.x = 0;
    pos.y = 410;
    gfx.fill(0x024972).rect(0, 0, 480, 70);
    new Energy();
    displayScore = new Text().align(TOP_RIGHT).xy(440, 445)
      .size(2).color(0xe65205);
  }

  var buffer = 0.0;
  public function addScore(s: Float) {
    buffer += s;
  }

  override public function update() {
    displayScore.text("" + Std.int(Game.main.score));
    if (buffer >= 10 && ticks > 0.2) {
      new Text().xy(455, 455)
        .color(0xe65205).move(0, -40).duration(0.3).text("+"+Std.int(buffer));
      Game.main.score += Std.int(buffer);
      buffer -= Std.int(buffer);
      ticks = 0.0;
    }
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
    gfx.clear()
      .fill(0x011f30).rect(0, 0, 400, 10)
      .fill(0xe65205).rect(0, 0, 400*Game.main.energy/100, 10);
  }
}

