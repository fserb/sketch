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
  var zoom: Float = 1.0;
  var points: Array<Float>;
  var added: Array<Float>;
  var addedStart: Float;
  var length: Float;
  override public function begin() {
    pos.x = pos.y = 0;
    alignment = TOPLEFT;
    points = new Array<Float>();
    added = new Array<Float>();
    addedStart = -1;
    for (i in 0...100) {
      points.push(100);
      added.push(100);
    }
  }

  inline function getidx(a: Float): Float {
    var ang = a%(2*Math.PI);
    return points.length*ang/(2*Math.PI);
  }

  function get(a: Float): Vec2 {
    var idx = getidx(a);
    var b = Std.int(idx);
    var p0 = new Vec2(240 + zoom*points[b]*Math.cos(2*Math.PI*b/points.length),
                      240 + zoom*points[b]*Math.sin(2*Math.PI*b/points.length));
    var e = (b + 1) % points.length;
    var p1 = new Vec2(240 + zoom*points[e]*Math.cos(2*Math.PI*e/points.length),
                      240 + zoom*points[e]*Math.sin(2*Math.PI*e/points.length));
    p1.sub(p0);
    p1.mul(idx - b);
    p0.add(p1);
    return p0;
  }

  public function normal(t: Float): Vec2 {
    var p = get(t).copy();
    p.x -= 240;
    p.y -= 240;
    p.normalize();
    return p;
  }

  public function addPath(a: Float, h: Float) {
    var idx = getidx(a);
    var a = Std.int(idx);
    added[a] = points[a] + h;
    var b = (a+1)%points.length;
    added[b] = points[b] + h;
  }

  public function closePath(t: Float) {
    for (i in 0...added.length) {
      points[i] = added[i];
    }
  }

  public function draw() {
    gfx.clear();
    gfx.line(2, 0x888888);
    var last = -1;
    for (i in 0...added.length) {
      if (added[i] != points[i]) {
        var x = 240 + zoom*added[i]*Math.cos(2*Math.PI*i/added.length);
        var y = 240 + zoom*added[i]*Math.sin(2*Math.PI*i/added.length);
        if (last == -1) {
          gfx.mt(x, y);
        }
        gfx.lt(x, y);
        last = i;
      } else if (last >= 0) {
        gfx.mt(240 + zoom*added[last]*Math.cos(2*Math.PI*last/added.length),
               240 + zoom*added[last]*Math.sin(2*Math.PI*last/added.length));
        last = -1;

      }
    }
    if (added[0] != points[0]) {
      gfx.lt(240 + zoom*added[0], 240);
      last = 0;
    }
    if (last >= 0) {
        gfx.mt(240 + zoom*added[last]*Math.cos(2*Math.PI*last/added.length),
               240 + zoom*added[last]*Math.sin(2*Math.PI*last/added.length));
    }

    gfx.line(2, 0xFFFFFF).mt(240 + zoom*points[0], 240);
    for (i in 0...points.length) {
      var h = points[i];
      gfx.lt(240 + zoom*h*Math.cos(2*Math.PI*i/points.length),
             240 + zoom*h*Math.sin(2*Math.PI*i/points.length));
    }
    gfx.lt(240 + zoom*points[0], 240);
  }

  override public function update() {
    draw();
    var mv = 0.0;
    for (p in points) {
      if (p > mv) mv = p;
    }
    for (p in added) {
      if (p > mv) mv = p;
    }
    var targetzoom = Math.min(1.0, 175.0/mv);
    var dz = targetzoom - zoom;
    trace(zoom, targetzoom);
    zoom += dz*Game.time;

  }
}

class Cursor extends Entity {
  var t: Float;
  var h: Float;
  var hv: Float;
  override public function begin() {
    gfx.fill(0xFFFFFF).circle(8, 8, 8);
    t = 0.0;
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

    if (h < 0) h =0.0;

    var n2 = n.copy();
    n2.mul(h);
    pos.add(n2);

    gfx.clear();
    gfx.fill(0xFFFFFF).circle(8, 8, 8);
    gfx.fill().line(2, 0x000000).mt(8,8).lt(8 + 8*n.x, 8 + 8*n.y);

    if (h > 0) {
      Game.one("Path").addPath(t, h);
    } else {
      Game.one("Path").closePath(t);
    }
    t += Game.time*0.75;
  }
}
