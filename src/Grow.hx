//@ ugl.bgcolor = 0xbf1b25

import vault.ugl.*;
import vault.EMath;
import vault.Vec2;

class Grow extends Micro {
  static public function main() {
    new Grow("Grow", "");
  }

  override public function end() {
  }

  override public function begin() {
    new Path();
    new Cursor();
  }


  override public function update() {
  }
}

class Path extends Entity {
  var points: Array<Vec2>;
  var added: Array<Vec2>;
  var addedStart: Float;
  var length: Float;
  override public function begin() {
    pos.x = pos.y = 0;
    alignment = TOPLEFT;
    points = new Array<Vec2>();
    added = new Array<Vec2>();
    addedStart = -1;
    for (i in 0...10) {
      points.push(new Vec2(240 + 100*Math.cos(2*Math.PI*i/10),
                           240 + 100*Math.sin(2*Math.PI*i/10)));
    }
    calcLength();
  }

  function calcLength() {
    length = 0.0;
    var lastp = points[points.length-1];
    for (p in points) {
      length += p.distance(lastp).length;
      lastp = p;
    }
    trace(length);
  }

  public function getidx(t: Float): Float {
    var l = 0.0;
    t = t % length;
    var lastp = points[0];
    for (i in 0...points.length) {
      var ni = (i+1)%points.length;
      var sl = points[ni].distance(lastp).length;
      l += sl;
      lastp = points[ni];
      if (l > t) {
        l -= sl;
        var d = i + (t-l)/sl;
        return d;
      }
    }
    return -1;
  }

  public function get(t: Float): Vec2 {
    var i = getidx(t);
    var si = Std.int(i);
    var p = points[si].copy();
    var p2 = points[(si+1)%points.length].distance(p);
    p2.mul(i-si);
    p.add(p2);
    return p;
  }

  public function normal(t: Float): Vec2 {
    var p = get(t).copy();
    p.x -= 240;
    p.y -= 240;
    p.normalize();
    return p;
  }

  public function addPath(t: Float, p: Vec2) {
    if (addedStart < 0) {
      addedStart = t;
    }
    added.push(p);
  }

  public function closePath(t: Float): Float {
    if (added.length == 0) return t;
    var start = getidx(addedStart);
    var end = getidx(t);
    var hbp = get(addedStart).copy();
    var hep = get(t).copy();

    // add half begin point
    points.insert(Std.int(start+1), hbp);

    // remove middle points
    var hole = Std.int(end)-Std.int(start);
    trace(start, end, hole);
    if (hole >= 0) {
      points.insert(Std.int(end+2), hep);
      points.splice(Std.int(start+2), hole);
    } else {
      points.insert(Std.int(end+1), hep);
      points.splice(Std.int(start+3), points.length - Std.int(start+2));
      points.splice(0, Std.int(end)+1);
      start = -2;
    }

    // add new path
    for (i in 0...added.length) {
      points.insert(Std.int(start+2) + i, added[i]);
    }


    added = [];
    addedStart = -1;

    calcLength();
    return t;
  }

  public function draw() {
    gfx.clear();
    if (added.length > 0) {
      var a = get(addedStart);
      gfx.line(2, 0x888888).mt(a.x, a.y);
      for (p in added) {
        gfx.lt(p.x, p.y);
      }
      gfx.mt(added[added.length-1].x, added[added.length-1].y);
    }

    gfx.line(2, 0xFFFFFF).mt(points[0].x, points[0].y);
    for (p in points) {
      gfx.lt(p.x, p.y);
    }
    gfx.lt(points[0].x, points[0].y);
    gfx.fill(0xFFFFFF);
    for (p in points) {
      gfx.circle(p.x, p.y, 2);
    }
  }

  override public function update() {
    draw();

    if (Game.key.up_pressed) {
      var p1 = points[0];
      var p2 = points[1];
      var pn = p2.distance(p1);
      pn.rotate(-Math.PI/2);
      pn.mul(10);
      var px = p1.copy();
      px.add(p2);
      px.mul(0.5);
      px.add(pn);
      points.insert(1, p1);
      points.insert(2, px);
      points.insert(3, p2);
    }
    if (Game.key.down_pressed) {
      points.splice(1, 1);
      points.splice(1, 1);
      points.splice(1, 1);
    }
  }
}

class Cursor extends Entity {
  var t: Float;
  var h: Float;
  var hv: Float;
  override public function begin() {
    gfx.fill(0xFFFFFF).circle(8, 8, 8);
    t = 500.0;
    h = 0.0;
    hv = 0.0;
  }

  override public function update() {
    pos = Game.one("Path").get(t);
    var n:Vec2 = Game.one("Path").normal(t);

    var ha = 0.0;

    var C1 = 0.1;
    var C2 = 10.0;

    if (Game.key.b1) {
      ha = 500.0;
    }

    if (hv > 0) {
      ha -= hv*hv*C1;
    } else {
      ha += hv*hv*C1;
    }
    ha -= h*C2;


    ha *= Game.time;
    h += Game.time*(hv + ha/2.0);
    hv += ha;

    // trace(Std.int(h), Std.int(hv), Std.int(ha));
    if (h < 0) h =0.0;

    var n2 = n.copy();
    n2.mul(h);
    pos.add(n2);

    gfx.clear();
    gfx.fill(0xFFFFFF).circle(8, 8, 8);
    gfx.fill().line(2, 0x000000).mt(8,8).lt(8 + 8*n.x, 8 + 8*n.y);

    if (h > 0) {
      Game.one("Path").addPath(t, pos.copy());
    } else {
      t = Game.one("Path").closePath(t);
    }
    t += Game.time*50;
  }
}
