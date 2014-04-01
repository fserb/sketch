// based on Aba Games' Satellite Catch

import vault.Rand;
import vault.ugl.*;
import vault.Vec2;

class Avoid extends Game {
  static public function main() {
    new Avoid("Avoid", "");
  }

  override public function initialize() {
    score = new Text().xy(10, 10).align(TOP_LEFT).size(2);
  }

  public var player: Player = null;
  public var spawner: Timer;
  var score: Text;

  override public function begin() {
    player = new Player();
    Game.orderGroups(["Enemy", "Player", "Particle", "Text"]);
    spawner = new Timer().every(1.5).run(function() { new Enemy(); });
  }

  override public function end() {
    player.remove();
    player = null;
    spawner.remove();
  }

  override public function update() {
    score.text("" + player.score);
  }
}

class Player extends Entity {
  public var size = 25.0;
  public var score = 0.0;
  override public function begin() {
    pos.x = 240;
    pos.y = 240;
    score = 0.0;
    art.size(3).color(0xe1b81f,0xa37d1d, 32).circle(size/3, size/3, size/3);
  }

  // var a = false;
  override public function update() {
    pos.x = Game.mouse.x;
    pos.y = Game.mouse.y;

    size += Game.time;

    art.circle(size/3, size/3, size/3);
  }

  public function chit(s: Float) {
    size -= s;
    if (size <= 0) {
      new Particle().color(0xe1b81f).xy(pos.x, pos.y)
                    .count(Const(150)).size(Rand(5, 9))
                    .delay(Const(0))
                    .duration(Const(5.0))
                    .speed(Rand(vel.length/10, 50));
      Game.endGame();
    }
  }
}

class Enemy extends Entity {
  var size = 0.0;
  override public function begin() {
    size = 7 + Math.random()*15;
    art.size(5).color(0xe11c57,0x861034, 23).circle(size/5, size/5, size/5);
    pos.x = 480*Math.random();
    pos.y = 480*Math.random();
  }

  // var a = false;
  var tv = 0.0;
  var tads = 0.0;
  override public function update() {
    tv += Game.time;

    var player: Player = Game.main.player;
    if (player == null) return;
    var x = player.pos.copy();
    x.sub(this.pos);
    x.normalize();
    x.mul(Math.sqrt(Game.totalTime * .00002) * size * Math.min(1.0, tv) * player.size * 7);
    vel.add(x);
    vel.mul(0.95);

    var ads = Std.int((size + player.size) * 2 / (pos.distance(player.pos) - size - player.size + .1));
    if (ads > 0) {
      tads += ads;
    } else {
      adsc();
    }

    var s = 100;
    if (pos.x < 0-s || pos.y < 0-s || pos.x > 480+s || pos.y > 480+s) {
      adsc();
      remove();
    }

    var d = pos.distance(player.pos);
    if (d < size + player.size) {
      adsc();
      player.chit(size);
      remove();
      new Particle().color(0xe11c57).xy(pos.x, pos.y)
                    .count(Rand(100, 20)).size(Rand(7, 5))
                    .delay(Const(0))
                    .duration(Const(0.5))
                    .speed(Rand(vel.length/10, 50));
    }

    for (en in Game.get("Enemy")) {
      var e: Enemy = cast en;
      if (e == this) continue;
      if (e.dead) continue;
      if (pos.distance(e.pos) > size + e.size) continue;

      if (size > e.size) {
        new Particle().color(0xe11c57).xy(e.pos.x, e.pos.y)
                      .count(Rand(100, 20)).size(Rand(7, 5))
                      .delay(Const(0))
                      .duration(Const(0.5))
                      .speed(Rand(e.vel.length/3, 100));
        size -= e.size;
        tads += e.tads;
        art.circle(size/5, size/5, size/5);
        e.remove();
      } else {
        new Particle().color(0xe11c57).xy(pos.x, pos.y)
                      .count(Rand(100, 20)).size(Rand(7, 5))
                      .delay(Const(0))
                      .duration(Const(0.5))
                      .speed(Rand(vel.length/3, 100));
        e.size -= size;
        e.tads += tads;
        e.art.circle(e.size/5, e.size/5, e.size/5);
        remove();
        return;
      }
    }
  }

  function adsc() {
    if (tads <= 0) return;
    new Text().text("+" + tads).duration(1).xy(pos.x, pos.y).move(0, -20);
    Game.main.player.score += tads;
    tads = 0;
  }
}
