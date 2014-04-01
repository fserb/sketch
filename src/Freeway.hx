//@ ugl.bgcolor = 0xababab

import vault.ugl.*;
import vault.EMath;
import vault.Vec2;
import vault.ugl.PixelArt.C;

class Freeway extends Game {
  static public function main() {
    Game.debug = true;
    new Freeway("Freeway", "");
  }

  override public function initialize() {
    Game.orderGroups(["Track", "Chicken", "Car", "Text" ]);
  }

  public var player: Player;

  override public function end() {
  }

  override public function begin() {
    new Track();
    player = new Player();
    new Car();
    new Chicken();
  }

  override public function update() {
    var dx = 50 - player.pos.x;

    var cars = 0;
    for (c in Game.get("Car")) {
      c.pos.x += dx;
      cars++;
    }
    for (c in Game.get("Chicken")) {
      c.pos.x += dx;
    }
    player.pos.x += dx;

    if (cars < 5) {
      new Car();
    }

  }
}

class Player extends Car {
  override public function begin() {
    art.size(6, 5, 5).obj([C.purple, C.black], CAR);
    lane = 4;
    pos.x = 50;
    pos.y = 238;
    vel.x = 60;
  }
  override public function update() {
    super.update();

    if (Game.key.up_pressed) { lane = EMath.max(0, lane-1); }
    if (Game.key.down_pressed) { lane = EMath.min(8, lane+1); }
  }
}

class Car extends Entity {
  var CAR = "1..1.0000000.00000001..1.";
  var lane: Int;
  override public function begin() {
    art.size(6, 5, 5).obj([C.darkgrey, C.black], CAR);
    lane = Std.int(Math.random()*8);
    pos.y = 42 + 42*lane + 28;
    pos.x = 500;
    vel.x = Math.random()*60;
  }
  override public function update() {
    var ly = 42 + 42*lane + 28;
    var dy = ly - pos.y;
    vel.y = 0.1*Math.min(42, dy)/Game.time;

    if (pos.x < -20) {
      remove();
    }
  }
}

class Chicken extends Entity {
  override public function begin() {
    art.size(3, 11, 8).obj([C.yellow],
      "......000..
       ......00000
       ....00000..
       00.000000..
       000000000..
       ..000000...
       ....00.....
       ....0000...");
    pos.x = pos.y = 240;
  }
  override public function update() {
  }
}

class Track extends Entity {
  override public function begin() {
    alignment = TOPLEFT;
    var a = art.size(3).color(0xFFFFFF);
    pos.x = pos.y = 0;
    for (l in 0...10) {
      for (r in 0...12) {
        a.hline(14*r, 14*r + 6, 16 + l*14);
      }
    }
    a.color(0x666666).rect(0, 0, 160, 14).rect(0, 146, 160, 14);
  }
  override public function update() {
  }
}
