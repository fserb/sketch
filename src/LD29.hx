//@ ugl.bgcolor = 0xFFFFFF

/*
Beneath the surface
===================

- trains passing by stations
- you can switch to different trains
- missions:
  - follow the passanger in a different train
  - get to a station in X secconds
  - catch a train in X seconds


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
  static public var white = 0xFFFFFF;
  static public var black = 0x1C140D;
  static public var green = 0xCBE86B;
  static public var purple = 0xdf9bea; // 0xF2E9E1;
  static public var blue = 0x6baee8;
  static public var orange = 0xe8996b;
  static public var clear = 0xF2E9E1;

  static public function line(l: Int) {
    return switch(l) {
      case 0: C.green;
      case 1: C.purple;
      case 2: C.blue;
      case 3: C.orange;
      default: C.clear;
    };
  }
}

class LD29 extends Game {
  static public function main() {
    Game.baseColor = 0x000000;
    new LD29("Beneath the Surface", "a LD29 game by Fernando Serboncini");
  }

  override public function begin() {
    new Grid();
  }

  override public function update() {
    var camera = new Vec2(0, 0);

    if (Game.key.left) camera.x -= 200*Game.time;
    if (Game.key.right) camera.x += 200*Game.time;
    if (Game.key.up) camera.y -= 200*Game.time;
    if (Game.key.down) camera.y += 200*Game.time;

    for (c in [ "Grid", "Station", "Train" ] ) {
      for (e in Game.get(c)) {
        e.pos.x -= camera.x;
        e.pos.y -= camera.y;
      }
    }
  }
}

class Grid extends Entity {
  static var layer = 10;
  var edges: Array<Edge>;
  var lines: Array<Int>;

  override public function begin() {
    alignment = TOPLEFT;
    createStations();
  }

  function createStations() {
    var points = new Array<Point>();

    var DIM = 480*5;
    pos.x = pos.y = -DIM/2.0;

    var attemps = 0;
    while (attemps < 1000 && points.length < 200) {
      attemps++;
      var p = new Point(Std.int(DIM*Math.random()), Std.int(DIM*Math.random()));

      var mindist:Float = DIM*DIM;
      for (s in points) {
        var d = (s.x - p.x)*(s.x - p.x) + (s.y - p.y)*(s.y - p.y);
        mindist = Math.min(mindist, Math.sqrt(d));
      }
      if (mindist < 150) continue;
      points.push(p);
    }
    trace(attemps + ", " + points.length);

    var vor = new Voronoi();
    var diagram = vor.compute(points, new Rectangle(0, 0, DIM, DIM));

    var stations = new Map<String, Station>();
    for (p in points) {
      stations[p.x + ":" + p.y] = new Station(p.x + pos.x, p.y + pos.y);
    }

    edges = diagram.edges;
    lines = new Array<Int>();
    for (e in diagram.edges) {
      if (e.lPoint == null || e.rPoint == null) continue;
      var left = stations.get(e.lPoint.x + ":" + e.lPoint.y);
      var right = stations.get(e.rPoint.x + ":" + e.rPoint.y);
      var line = Std.int(4*Math.random());
      left.conn.push(right);
      left.line.push(line);
      right.conn.push(left);
      right.line.push(line);
      lines.push(line);
    }

    for (s in stations.iterator()) {
      new Train(s);
    }

    drawTunnels();
  }

  function drawTunnels() {
    gfx.clear();

    var i = 0;
    for (e in edges) {
      if (e.lPoint == null || e.rPoint == null) continue;
      var c = C.line(lines[i++]);
      gfx.line(6, c)
        .mt(e.lPoint.x, e.lPoint.y).lt(e.rPoint.x, e.rPoint.y);
    }
  }

  override public function update() {
  }
}

class Station extends Entity {
  static var layer = 11;
  public var conn: Array<Station>;
  public var line: Array<Int>;

  override public function begin() {
    pos.x = args[0];
    pos.y = args[1];
    conn = new Array<Station>();
    line = new Array<Int>();
    gfx.fill(C.black).circle(8, 8, 8)
       .fill(C.white).circle(8, 8, 6)
       .fill(C.black).circle(8, 8, 4);
  }
}

class Train extends Entity {
  static var layer = 12;
  var from: Station;
  var to: Station;
  var line: Int;

  override public function begin() {
    from = args[0];
    var s = Std.int(from.conn.length*Math.random());
    to = from.conn[s];
    line = from.line[s];
    pos.x = from.pos.x;
    pos.y = from.pos.y;
    angle = to.pos.distance(from.pos).angle;
    gfx.fill(C.line(line)).line(2, C.black).rect(0, 0, 50, 16);
  }

  function findTo() {
    var except = from;
    from = to;
    to = null;
    var picks = 1;
    for (i in 0...from.conn.length) {
      if (from.line[i] != line) continue;
      if (to != null && from.conn[i] == except) continue;
      if (to == null || to == except || Math.random() < 1/picks) {
        to = from.conn[i];
      }
      picks++;
    }
  }

  override public function update() {
    var d = to.pos.distance(pos);
    var da = EMath.angledistance(d.angle, angle);
    if (da > 0) da = Math.min(da, Math.PI/2*Game.time);
    else if (da < 0) da = -Math.min(-da, Math.PI/2*Game.time);

    angle += da;

    if (Math.abs(da) < Math.PI/64*Game.time) {
      var fulllength = d.length;
      d.length = Math.min(fulllength, 200*Game.time);
      pos.add(d);
      if (fulllength <= 200*Game.time) {
        findTo();
      }
    }
  }

}

