//@ ugl.bgcolor = 0xEEEEEE

import vault.ugl.*;
import flash.geom.Point;
import flash.geom.Rectangle;
import vault.ds.Tuple;
import vault.EMath;
import vault.geom.Vec2;
import vault.Ease;

class C {
  static public var bg = 0xEEEEEE;
  static public var color = 0x2c4350;
  static public var light = 0xd1d6d8;
}

typedef Line = {
  var x1: Float;
  var y1: Float;
  var z1: Float;
  var x2: Float;
  var y2: Float;
  var z2: Float;
}

class Polarwaves extends Motion {
  static inline var tau = 6.28318530717958647692;
  var radius = 0.0;

  static public function main() {
    new Polarwaves();
  }

  override public function begin() {
    radius = 200;
    total = 100;
    fps = 30.0;
  }

  function render(points: Array<Vec2>) {
    var lines = new Array<Line>();

    for (i in 1...points.length) {
      if (points[i] == null || points[i-1] == null) continue;
      lines.push({ x1: 240 + radius*Math.cos(points[i-1].y)*Math.sin(points[i-1].x),
                   y1: 240 + radius*Math.sin(points[i-1].y),
                   z1: 0.5 + 0.5*Math.cos(points[i-1].y)*Math.cos(points[i-1].x),
                   x2: 240 + radius*Math.cos(points[i].y)*Math.sin(points[i].x),
                   y2: 240 + radius*Math.sin(points[i].y),
                   z2: 0.5 + 0.5*Math.cos(points[i].y)*Math.cos(points[i].x) });
    }
    if (points[0] != null && points[points.length-1] != null) {
      lines.push({ x1: 240 + radius*Math.cos(points[points.length-1].y)*Math.sin(points[points.length-1].x),
                   y1: 240 + radius*Math.sin(points[points.length-1].y),
                   z1: 0.5 + 0.5*Math.cos(points[points.length-1].y)*Math.cos(points[points.length-1].x),
                   x2: 240 + radius*Math.cos(points[0].y)*Math.sin(points[0].x),
                   y2: 240 + radius*Math.sin(points[0].y),
                   z2: 0.5 + 0.5*Math.cos(points[0].y)*Math.cos(points[0].x) });
     }

    lines.sort(function(a, b) {
      var za = (a.z1 + a.z2)/2.0;
      var zb = (b.z1 + b.z2)/2.0;
      if (za < zb) return -1;
      if (za > zb) return 1;
      return 0;
    });


    for (l in lines) {
      gfx.fill(Color.lerp(C.light, C.color, (l.z1 + l.z2)/2.0));
      gfx.circle((l.x1 + l.x2)/2, (l.y1 + l.y2)/2, 2);
      /*gfx.line(5, Color.lerp(C.light, C.color, (l.z1 + l.z2)/2.0));*/
      /*gfx.mt(l.x1, l.y1);
      gfx.lt(l.x2, l.y2);*/
    }
  }

  override public function update() {
    var points = new Array<Vec2>();

    var phi = -tau/2 + (tau/16)*frac;
    var xxx = 2*tau*frac;

    var divs = 500;
    for (d in 0...8) {
      var ppp = phi + (tau/4.0) + d*tau/16.0;
      var yyy = xxx*(1 + d)/2;
      for (i in 0...divs)  {
        points.push(Vec2.make(tau*i/divs, ppp + (tau/64)*Math.cos(yyy + 5*tau*i/divs) ));
      }
      points.push(Vec2.make(0, ppp + (tau/64)*Math.cos(yyy) ));
      points.push(null);
    }

    gfx.clear().size(480, 480);
    render(points);
  }
}
