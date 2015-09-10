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

class Node {
  public var pos: Vec2;
  public var normal: Vec2;
  public var next: Node;
  public function new(x: Float, y: Float, next: Node) {
    pos = new Vec2(x, y);
    this.next = next;
    normal = null;
  }

  public function frac(f: Float): Vec2 {
    var p2 = next.pos.distance(pos);
    p2.mul(f - Std.int(f));
    var p = pos.copy();
    p.add(p2);
    return p;
  }
}

class Path extends Entity {
  var zoom: Float = 1.0;

  var points: Node;
  var added: Node;
  var addedStart: Float;
  var length: Float;

  override public function begin() {
    pos.x = pos.y = 0;
    alignment = TOPLEFT;
    points = new Node(240 + 100, 240, null);
    points.next = points;
    added = null;
    addedStart = -1;
    var p: Node = points;
    for (i in 1...10) {
      p.next = new Node(240 + 100*Math.cos(2*Math.PI*i/10),
        240 + 100*Math.sin(2*Math.PI*i/10), points);
      p = p.next;
    }
    calcLength();
  }

  function calcLength() {
    var p = points;
    trace("length");
    do {
      var d = p.next.pos.distance(p.pos).length;
      if (d < 10) {
        if (p.next == points) {
          points = p.next.next;
        }
        p.next = p.next.next;
        continue;
      }

      p = p.next;
    } while (p != points);
    trace("skip");
    length = 0.0;
    var p = points;
    var prev: Node = points;
    while (prev.next == points) prev = prev.next;
    do {
      length += p.next.pos.distance(p.pos).length;
      p.normal = prev.pos.distance(p.next.pos).normal();
      p.normal.normalize();
      prev = p;
      p = p.next;
    } while (p != points);
  }

  function get(t: Float): Vec2 {
    var l = 0.0;
    t = t % length;
    var p = points;
    do {
      var sl = p.next.pos.distance(p.pos).length;
      l += sl;
      if (l > t) {
        return p.frac((t-(l-sl))/sl);
      }
      p = p.next;
    } while (p != points);
    return new Vec2(0, 0);
  }

  public function normal(t: Float): Vec2 {
    var l = 0.0;
    t = t % length;
    var p = points;
    do {
      var sl = p.next.pos.distance(p.pos).length;
      l += sl;
      if (l > t) {
        l -= sl;
        var r1 = p.normal.copy();
        var r2 = p.next.normal.distance(r1);
        r2.mul((t-l)/sl);
        r1.add(r2);
        return r1 ;
      }
      p = p.next;
    } while (p != points);
    return new Vec2(0, 0);
  }

  public function addPath(t: Float, p: Vec2) {
    if (addedStart < 0) {
      addedStart = t;
    }
    if (added == null) {
      added = new Node(p.x, p.y, null);
      added.next = added;
    } else {
      var a = added;
      while (a.next != added) a = a.next;
      a.next = new Node(p.x, p.y, added);
    }
  }

  public function closePath(addedEnd: Float): Float {
    if (added == null) return addedEnd;
    if (addedEnd < addedStart) {
      var t = addedEnd;
      addedEnd = addedStart;
      addedStart = t;
    }

    var l = 0.0;
    var tstart = addedStart % length;
    var tend = addedEnd % length;
    var stepstart = 0.0;
    var stepend = 0.0;
    var p = points;
    var startNode: Node = null;
    var endNode: Node = null;
    do {
      var sl = p.next.pos.distance(p.pos).length;
      l += sl;
      if (startNode == null && l > tstart) {
        stepstart = (tstart-(l-sl))/sl;
        startNode = p;
      }
      if (endNode == null && l > tend) {
        stepend = (tend-(l-sl))/sl;
        endNode = p;
      }
      p = p.next;
    } while (p != points);
    // add half begin point.
    var r1 = startNode.frac(stepstart);
    startNode.next = new Node(r1.x, r1.y, startNode.next);

    // add half end point.
    var r1 = endNode.frac(stepend);
    endNode.next = new Node(r1.x, r1.y, endNode.next);

    // remove middle points.
    var la = added;
    while (la.next != added) la = la.next;
    startNode.next.next = added;
    la.next = endNode.next;

    added = null;
    addedStart = -1;
    points = endNode.next;

    calcLength();
    return 0;
  }

  public function draw() {
    gfx.clear();

    if (added != null) {
      gfx.line(2, 0x888888);
      var p = added;
      gfx.mt(added.pos.x, added.pos.y);
      do {
        gfx.lt(p.pos.x, p.pos.y);
        p = p.next;
      } while (p != added);
      gfx.mt(p.pos.x, p.pos.y);
    }

    gfx.line(2, 0xFFFFFF);
    var p = points;
    gfx.mt(points.pos.x, points.pos.y);
    do {
      gfx.lt(p.pos.x, p.pos.y);
      p = p.next;
    } while (p != points);
    gfx.lt(points.pos.x, points.pos.y);

    p = points;
    do {
      gfx.circle(p.pos.x, p.pos.y, 3);
      p = p.next;
    } while (p != points);
  }

  override public function update() {
    draw();
    var mv = 1.0;
    var targetzoom = Math.min(1.0, 175.0/mv);
    var dz = targetzoom - zoom;
    zoom += dz*Game.time;
  }
}

class Cursor extends Entity {
  var t: Float;
  var h: Float;
  var hv: Float;
  var normal: Vec2;
  var direction: Float;

  override public function begin() {
    gfx.fill(0xFFFFFF).circle(8, 8, 8);
    t = 0.0;
    h = 0.0;
    hv = 0.0;
    normal = null;
    direction = 1.0;
  }

  override public function update() {
    pos = Game.one("Path").get(t);

    var ha = 0.0;

    var C1 = 0.1;
    var C2 = 10.0;

    if (Game.key.b1 || Game.mouse.button) {
      ha = 500.0;
      normal = Game.one("Path").normal(t);
    }

    if (normal == null) {
      t += Game.time*50*direction;
      return;
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

    var n2 = normal.copy();
    n2.mul(h);
    pos.add(n2);

    gfx.clear();
    gfx.fill(0xFFFFFF).circle(8, 8, 8);
    gfx.fill().line(2, 0x000000).mt(8,8).lt(8 + 8*normal.x, 8 + 8*normal.y);

    if (h > 0) {
      Game.one("Path").addPath(t, pos);
    } else {
      t = Game.one("Path").closePath(t);
      if (normal != null) {
        normal = null;
        direction = -direction;
      }
    }
    t += Game.time*50*direction;
  }
}
