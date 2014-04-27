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
    new Train(Game.one("Station"));
  }

  override public function update() {
    var camera = new Vec2(0, 0);

    var t = Game.one("Train");
    camera.x = t.pos.x - 240;
    camera.y = t.pos.y - 240;

    for (c in [ "Grid", "Station", "Train", "Selection" ] ) {
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
      if (mindist < 100) continue;
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
    for (e in diagram.edges) {
      if (e.lPoint == null || e.rPoint == null) continue;
      var left = stations.get(e.lPoint.x + ":" + e.lPoint.y);
      var right = stations.get(e.rPoint.x + ":" + e.rPoint.y);
      left.conn.push(right);
      right.conn.push(left);
    }

    for (e in Game.get("Station")) {
      var s: Station = cast e;
      s.conn.sort(function(a, b) {
        var ang_a = a.pos.distance(s.pos).angle;
        var ang_b = b.pos.distance(s.pos).angle;
        if (ang_a < ang_b) {
          return -1;
        } else if (ang_a > ang_b) {
          return 1;
        }
        return 0;
      });
    }

    drawTunnels();
  }

  function drawTunnels() {
    gfx.clear();

    var i = 0;
    for (e in edges) {
      if (e.lPoint == null || e.rPoint == null) continue;
      gfx.line(6, C.clear)
        .mt(e.lPoint.x, e.lPoint.y).lt(e.rPoint.x, e.rPoint.y);
    }
  }

  override public function update() {
  }
}

class Station extends Entity {
  static var layer = 11;
  public var conn: Array<Station>;

  override public function begin() {
    pos.x = args[0];
    pos.y = args[1];
    conn = new Array<Station>();
    gfx.fill(C.black).circle(8, 8, 8)
       .fill(C.white).circle(8, 8, 6)
       .fill(C.black).circle(8, 8, 4);
  }
}

class Selection extends Entity {
  static var layer = 20;
  var from: Station;
  var to: Station;

  override public function begin() {
    from = args[0];
    to = args[1];



    alignment = TOPLEFT;
    pos.x = pos.y = 0;
    gfx.line(8, args[2] == null ? C.purple : args[2]).mt(from.pos.x, from.pos.y).lt(to.pos.x, to.pos.y);
  }
}



class Train extends Entity {
  static var layer = 25;
  var from: Station;
  var to: Station;
  var selection: Int;
  var sel: Selection;

  override public function begin() {
    from = args[0];
    var s = Std.int(from.conn.length*Math.random());
    to = from.conn[s];
    pos.x = from.pos.x;
    pos.y = from.pos.y;
    angle = to.pos.distance(from.pos).angle;
    gfx.fill(C.white).line(2, C.green).rect(0, 0, 50, 16);
    sel = null;
    select(0);
  }

  function findTo() {
    var except = from;
    from = to;
    to = null;
    var picks = 1;
    for (i in 0...from.conn.length) {
      if (to != null && from.conn[i] == except) continue;
      if (to == null || to == except || Math.random() < 1/picks) {
        to = from.conn[i];
      }
      picks++;
    }
  }

  function clearSelect() {
    if (sel != null) {
      sel.remove();
      sel = null;
    }
  }

  function select(s: Int) {
    selection = (to.conn.length + s) % to.conn.length;
    clearSelect();
    sel = new Selection(to, to.conn[selection], null);
  }

  static var TURNSPEED = 1.0;
  static var ACCSPEED = 150.0;

  override public function update() {

    var d = to.pos.distance(pos);
    var da = EMath.angledistance(d.angle, angle);
    if (da > 0) da = Math.min(da, Math.PI*TURNSPEED*Game.time);
    else if (da < 0) da = -Math.min(-da, Math.PI*TURNSPEED*Game.time);

    angle += da;

    var acc = ACCSPEED;
    if (Game.key.up) {
      acc *= 1.2;
    }


    if (Math.abs(da) < Math.PI/64*Game.time) {
      var fulllength = d.length;
      d.length = Math.min(fulllength, acc*Game.time);
      pos.add(d);
      if (fulllength <= acc*Game.time) {
        clearSelect();
        from = to;
        to = to.conn[selection];
        var cur = to.pos.distance(from.pos).angle;

        selection = 0;
        var ang = 100.0;
        for (i in 0...to.conn.length) {
          var an = Math.abs(
            EMath.angledistance(to.conn[i].pos.distance(to.pos).angle, cur));
          if (an < ang) {
            ang = an;
            selection = i;
          }
        }
        select(selection);
      }
    }

    if (Game.key.left_pressed) select(selection - 1);
    if (Game.key.right_pressed) select(selection + 1);
  }

}

