// based on Aba Games' WASD THRUST

import vault.ugl.*;
import vault.EMath;
import vault.Vec2;

class Up extends Game {
  var camera: Vec2;
  var score: Int;
  var display: Text;
  var adds: Float;
  static public function main() {
    // Game.debug = true;
    new Up("Up", "");
  }

  override public function initialize() {
  }

  var player: Player;
  override public function begin() {
    Game.orderGroups(["Obstacle", "Gold", "Player", "Particle", "Text"]);

    display = new Text().xy(10, 10).align(TOP_LEFT).size(2);

    player = new Player();
    player.pos.x = player.pos.y = 240;
    camera = Vec2.make(0, 0);

    score = 0;
    adds = 0.0;
  }

  override public function end() {
  }

  override public function update() {
    camera.y = Math.max(50*Game.time, 200-player.pos.y);
    camera.x = 240-player.pos.x;

    player.pos.add(camera);

    var valid = 0;
    for (type in [ "Obstacle", "Gold" ]) {
      for (obj in Game.get(type)) {
        var p2:Vec2 = obj.pos;
        p2.add(camera);
        if (p2.x >= 0 && p2.x <= 480 && p2.y <= 480) {
          valid++;
        }
      }
    }

    if (valid < 10) {
      if (Math.random() < 0.1) {
        new Gold();
        } else {
        new Obstacle();
      }
      valid++;
    }
    adds += valid*Game.time/10.0;
    if (adds >= 1.0) {
      score += 1;
      adds -= 1.0;
    }

    display.text("" + score);
  }
}

class Engine extends Entity {
  var player: Player;
  var relative_angle: Float;
  var force: Float;
  public function new(p:Player, a:Float, n:String) {
    super();
    player = p;
    relative_angle = a;
    force = 0.0;
    art
      .size(5, 4, 4).color(0xaa9936, 0x988946, 23).rect(0, 0, 4, 4)
      .color(0xFFFFFF).text(1.8, 1.8, n, 2);
  }

  override public function update() {
    pos = player.pos.copy();
    var d = Vec2.make(30, 0);
    d.rotate(relative_angle + player.angle);
    pos.add(d);
    angle = player.angle;
  }

  public function throtle() {
    force = Math.min(5, force + 20*Game.time);
    player.thrust(force, relative_angle + Math.PI);
    new Particle().color(0xaa9936).count(force/5, 2).size(5, 5)
      .xy(pos.x, pos.y).speed(force*50, 100)
      .direction(angle + relative_angle - Math.PI/8, Math.PI/4)
      .delay(0, 0.05).duration(0.25, 0.1);
  }
}

class Player extends Entity {
  var engines: Array<Engine>;
  public function new() {
    super();
    art.color(0x2ca244,0x1e702f, 253).size(20, 4, 4)
       .rect(0, 1.5, 4, 1).rect(1.5, 0, 1, 4);
    engines = new Array<Engine>();
    var strings = [ "D", "W", "A", "S" ];
    for (i in 0...4) {
      engines.push(new Engine(this, -i*Math.PI/2.0, strings[i]));
    }

    addHitBox(Rect(0*20, 1.5*20, 4*20, 1*20));
    addHitBox(Rect(1.5*20, 0*20, 1*20, 4*20));
  }

  override public function begin() {
  }

  public function thrust(force: Float, ang: Float) {
    var a = Vec2.make(force, 0);
    a.rotate(angle + ang);
    accelerate(a);
  }

  override public function update() {
    if (Game.key.right) { engines[0].throtle(); }
    if (Game.key.up) { engines[1].throtle(); }
    if (Game.key.left) { engines[2].throtle(); }
    if (Game.key.down) { engines[3].throtle(); }

    if (Game.key.b1) {
      angle -= 2*Math.PI*Game.time;
    }
    if (Game.key.b2) {
      angle += 2*Math.PI*Game.time;
    }

    var b = vel.copy();
    b.mul(-0.01);
    accelerate(b);

    angle += Game.time*vel.x/200;

    if (pos.y > 500) {
      kill();
    }
  }

  public function kill() {
    new Particle().color(0x2ca244).count(100)
      .xy(pos.x, pos.y)
      .size(5, 25).speed(20, 30).delay(0).duration(2, 0.5);
    for (e in engines) {
      e.remove();
    }
    remove();
    Game.endGame();
  }
}

class Obstacle extends Entity {
  override public function begin() {
    art.color(0xac0213, 0x881511, 52).size(7, 4, 4).rect(0, 1.5, 4, 1).rect(1.5, 0, 1, 4);
    pos.x = 480*Math.random();
    pos.y = -20 -460*Math.random();
    angle = 2*Math.PI*Math.random();

    addHitBox(Rect(0, 0, 7*4, 7*4));
  }

  override public function update() {
    if (hit(Game.main.player)) {
      Game.main.player.kill();
      remove();
    }

    if (pos.y >= 500) {
      Game.main.score += 5;
      new Text().text("+5").duration(1).xy(EMath.clamp(pos.x, 10, 470), 480).move(0, -20);
     remove();
    }
  }
}

class Gold extends Entity {
  var points: Int;
  override public function begin() {
    points = Math.round(1 + Math.random()*8)*10;
    art.color(0xe3c61e, 0xdacc3d, 23).size(3, 8, 7).rect(0, 0, 8, 7)
       .color(0xca8727).lrect(0, 0, 8, 7)
       .color(0x604013).text(4, 3.5, "" + points, 1);

    pos.x = 480*Math.random();
    pos.y = -20 -460*Math.random();

    addHitBox(Rect(0, 0, 8*3, 7*3));
  }

  override public function update() {
    if (hit(Game.main.player)) {
      Game.main.score += points;
      new Text().text("+" + points).duration(1).xy(pos.x, pos.y).move(0, -20);
      remove();
    }

    if (pos.y >= 500) remove();
  }
}
