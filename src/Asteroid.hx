//@ ugl.bgcolor = 0xbf1936

import vault.ugl.*;
import vault.EMath;
import vault.Vec2;
import vault.ugl.PixelArt.C;

class Asteroid extends Game {
  static public function main() {
    Game.debug = true;
    new Asteroid("Super Asteroid", "super hot asteroid");
  }

  override public function initialize() {
    Game.orderGroups(["Maze", "Key", "Gate", "Bot", "Player", "Final", "Transition", "Text"]);
  }

  override public function end() {
  }

  override public function begin() {
    new Player();
  }

  override public function final() {
  }

  public var realtime = 0.0;
  override public function update() {
    if (!(Game.key.any)) {
      realtime = Game.time;
      Game.time = 0;
    }
  }
}

class Player extends Entity {
  override public function begin() {
    sprite.graphics.beginFill(0xFFFFFF);
    sprite.graphics.moveTo(16, 8);
    sprite.graphics.lineTo(0, 16);
    sprite.graphics.lineTo(4, 8);
    sprite.graphics.lineTo(0, 0);
    sprite.graphics.lineTo(16, 8);
    pos.x = pos.y = 240;
    addHitBox(Rect(0, 0, 16, 16));
  }

  var reload = 0.0;
  override public function update() {
    if (Game.key.left) angle -= 1.5*Math.PI*Game.main.realtime;
    if (Game.key.right) angle += 1.5*Math.PI*Game.main.realtime;
    if (Game.key.up) {
      var v = new Vec2(100*Game.time, 0);
      v.rotate(angle);
      vel.add(v);
      vel.length = Math.min(500, vel.length);
    }

    reload = Math.max(0.0, reload - Game.time);
    if (Game.key.b1 && reload <= 0.0) {
      new Bullet(this);
      reload += 0.2;
    }
    if (pos.x < 0 || pos.x > 480) pos.x = 480 - pos.x;
    if (pos.y < 0 || pos.y > 480) pos.y = 480 - pos.y;
  }
}

class Bullet extends Entity {
  var fromPlayer: Bool;
  override public function new(src: Entity) {
    fromPlayer = (src == Game.one("Player"));
    super();
    pos.x = src.pos.x;
    pos.y = src.pos.y;
    angle = src.angle;
    vel.length = 100;
    vel.angle = angle;
  }

  override public function begin() {
    art.color(fromPlayer ? 0xFFFFFF : 0x000000).rect(0, 0, 4, 4);
  }
}

class Asteroid extends Entity {
  override public function begin() {

  }

}
