//@ ugl.bgcolor = 0x444444

import vault.ugl.*;
import vault.EMath;
import vault.Vec2;

class C extends Color.ColorsArne {
}

class Musician extends Game {
  public var score: Int;
  var display: Text;
  public var bpm: Float;
  public var level: Int;
  static public function main() {
    new Musician("Street Musician", "Collect coins, avoid tomatoes");
  }

  public var player: Player;
  public var hat: Hat;
  public var holder: Holder;
  public var combo: Int;

  override public function initialize() {
    Game.orderGroups(["Hat", "Holder", "Coin", "Tomato", "Note", "Player", "Text"]);
  }

  override public function end() {
    player.remove();
  }

  override public function final() {
    new Text().xy(240, 200).size(2).text("you made");
    new Text().xy(240, 240).size(4).text("$"+ score);
    new Text().text("click to begin").align(BOTTOM_CENTER).xy(240, 470).size(1).color(0xFF999999);
  }

  override public function begin() {
    player = new Player();
    hat = new Hat();

    holder = new Holder();

    var n = new Note();
    score = 0;
    display = new Text().xy(20, 10).align(TOP_LEFT).size(2);
    bpm = 60.0;
    level = 0;
    combo = 0;
  }

  var tempo = 0.0;
  override public function update() {
    tempo += Game.time;

    var spb = 60.0/(4*bpm);
    if (tempo >= spb) {
      tempo -= spb;
      if (Math.random() < 0.2) {
        new Note();
      }
    }

    display.text("$" + score);

    bpm = 60.0 + 140.0*score/2000.0 + combo;
  }
}

class Holder extends Entity {
  var FORMAT = "..0..
       .0.0.
       0...0
       .0.0.
       .000.";

  override public function begin() {
    art.size(4, 5, 5).obj([0x000000], FORMAT);
    pos.x = 240;
    pos.y = 80;
    addHitBox(Rect(0, 0, 20, 20));
  }

  override public function update() {
    var minx = 1e99;
    var bestn: Note = null;
    for (n in Game.get("Note")) {
      var no: Note = cast n;
      no.front = false;
      if (no.missed || no.good) continue;
      if (no.pos.x < minx) {
        minx = no.pos.x;
        bestn = no;
      }
    }
    if (bestn != null) {
      bestn.front = true;
    }
  }
}


class Note extends Entity {
  var NOTE = "
       ..0..
       .000.
       00000
       .000.
       .000.";
  public var front = false;
  public var onhit = false;
  public var missed = false;
  public var good = false;
  var snd: Sound;
  override public function begin() {
    art.cache(0).size(4, 5, 5).obj([C.orange], NOTE);
    pos.x = 500;
    pos.y = 80;
    addHitBox(Rect(0, 0, 20, 20));
    snd = new Sound("note").blip(0);
  }

  override public function update() {
    if (hit(Game.main.holder)) {
      if (front) {
        art.cache(1).size(4, 5, 5).obj([C.red], NOTE);
      }

      onhit = true;
      if (Game.key.up_pressed && front) {
        good = true;
        snd.play();
        Game.main.combo++;
        var dist = Math.abs(pos.x  - Game.main.holder.pos.x)/20.0;
        new Coin(dist);
      }
    } else if (front) {
      if (onhit) {
        onhit = false;
        missed = true;
        Game.main.combo = 0;
        new Tomato();
      }
      if (Game.key.up_pressed) {
        missed = true;
        Game.main.combo = 0;
        new Tomato();
      }
    }

    if (!good && !missed) {
      pos.x -= Game.main.bpm*Game.time;
    } else {
      sprite.alpha -= Game.time/0.5;
    }

    if (good) {
      pos.y -= 100*Game.time;
    }

    if (missed) {
      pos.y += 100*Game.time;
    }
    if (sprite.alpha == 0) {
      remove();
    }
  }
}

class Player extends Entity {
  override public function begin() {
    art.size(8, 5, 5).obj([C.darkgrey, C.red, C.orange, C.pink],
      "..1..
       .111.
       .3322
       .000.
       .0.0.
      ");
    pos.x = 240;
    pos.y = 140;
    addHitBox(Rect(0, 0, 40, 40));
  }

  override public function update() {
    if (Game.key.left) angle -= Math.PI*2*Game.time/3.0;
    if (Game.key.right) angle += Math.PI*2*Game.time/3.0;
    if (angle != 0) {
      angle -= angle*0.02;
    }
    angle = EMath.clamp(angle, -Math.PI/5, Math.PI/5);

    pos.x = 240 + 200*Math.sin(angle);
    pos.y = 340 - 200*Math.cos(angle);

  }
}

class Tomato extends Entity {
  override public function begin() {
    pos.x = Math.random()*480;
    pos.y = 500;

    var tx = 120 + 240*Math.random();

    vel.x = (tx-pos.x)/2.0;
    vel.y = (140-500)/2.0;

    art.size(4, 5, 5).color(C.red).circle(2.5, 2.5, 2)
      .color(C.green).dot(2, 1).dot(2, 0).dot(3, 0);
    addHitBox(Circle(10, 10, 8));
  }

  override public function update() {
    if (hit(Game.main.player)) {
      new Particle().color(C.red).xy(pos.x, pos.y).count(500)
        .size(10, 5).speed(0, vel.length/2.0)
        .delay(0).duration(0.5, 0.5);
      remove();
      new Sound("tomato").explosion(16).play();
      Game.endGame();
    }

    if (pos.y < 0) {
      remove();
    }
  }
}

class Coin extends Entity {
  var value: Int;
  override public function begin() {
    var dist: Float = args[0];
    value = Math.round(Game.main.combo + (1.0 - dist)*9);
    pos.x = Math.random()*480;
    pos.y = 500;

    var tx = 120 + 240*Math.random();

    vel.x = (tx-pos.x)/1.0;
    vel.y = (140-500)/1.0;

    art.size(2, 5, 5).color(C.yellow).circle(2.5, 2.5, 2.5);
    addHitBox(Circle(5, 5, 5));
  }

  override public function update() {
    if (hit(Game.main.player)) {
      Game.main.score += value;
      new Text().text("$" + value).duration(1).xy(pos.x, pos.y).move(0, -20);
      new Sound("coin").coin(12).play();
      remove();
    }

    if (pos.y < 0) {
      remove();
    }
  }
}

class Hat extends Entity {
  var HAT = "....0000.00.";
  override public function begin() {
    art.size(8, 4, 3).obj([C.black], HAT);
    pos.x = pos.y = 240;
  }
}

