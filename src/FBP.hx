//@ ugl.bgcolor = 0x4ec0ca

/*
*/

import flash.geom.Point;
import flash.geom.Rectangle;
import vault.ds.Tuple;

class C {
  static public var bg = 0x4ec0ca;
  static public var dark = 0x533846;
  static public var white = 0xfafafa;
  static public var bird = 0xf8b733;
  static public var birdLight = 0xfad78c;
  static public var birdDark = 0xe0802c;
  static public var birdLips = 0xfc3800;
  static public var grey = 0xd7e6cc;
}

class FBP extends Micro {
  static public function main() {
    Micro.baseColor = 0x000000;
    new FBP("FlappyBird Puzzle", "");
  }

  override public function begin() {
    new Bird();
    new Coin();
  }
}

class Bird extends Entity {
  var waiting: Bool = true;
  var direction: Bool = false;
  override public function begin() {
    pos.x = pos.y = 240;

    art.size(2,17,12).obj([C.dark,C.white,C.grey,
                           C.bird, C.birdLight, C.birdDark, C.birdLips], "
......000000.........004440110.......04433011110.....0433330211010..
.03333330211010...00000333021110..0111110333000000.04111403306666660
.000005506000000...05555550666660....005555500000.......00000.......");

  }

  override public function update() {
    var button = Game.key.b1_pressed || Game.mouse.button_pressed;
    if (waiting) {
      if (button) {
        waiting = false;
      }
      return;
    }
    if (!direction && pos.x >= 460) {
      direction = true;
    } else if (direction && pos.x <= 20) {
      direction = false;
    }
    if (pos.y < 20) {
      pos.y = 20;
      vel.y = Math.abs(vel.y)*0.75;
    }
    if (pos.y > 460) {
      pos.y = 460;
      vel.y = -Math.abs(vel.y)*0.75;
    }

    vel.y += 5.0;
    vel.x = direction ? -100.0 : 100.0;

    sprite.scaleX = direction ? -1 : 1;


    if (button) {
      vel.y = -200.0;
    }

  }
}

class Coin extends Entity {
  override public function begin() {
    pos.x = pos.y = 50;
    gfx.fill(0xe9e1e1).circle(10,10,10).fill(null);
    gfx.line(2, 0xffffff).arc(10,12,10,10,0,Math.PI);
    gfx.line(2, 0xc8c0c0).arc(10,8,10,10, Math.PI, 2*Math.PI);
    gfx.line(2, 0x847f7f).circle(10,10,10);
  }

  override public function update() {
    if (hitGroup("Bird")) {
      remove();
    }
  }
}
