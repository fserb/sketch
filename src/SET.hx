//@ ugl.bgcolor = 0xFAFAFA

/*
SET
===

*/

import vault.ugl.*;
import flash.geom.Point;
import flash.geom.Rectangle;
import vault.ds.Tuple;
import vault.EMath;
import vault.Vec2;
import vault.Ease;

class C {
  static public var black:UInt = 0x010101;
  static public var white:UInt = 0xFAFAFA;

  static public var COLORS = [ 0xff6819, 0xc0dc61, 0x1ebed8, 0xfec804, 0xe284cc ];
}

class SET extends Micro {
  static public function main() {
    Micro.baseColor = C.black;
    new SET("SET", "");
  }

  override public function begin() {
    var a = 8;
    new Card(80, 240, 0 + 0);
    new Card(240, 240, 1 + 4 + 64 + 16);
    new Card(400, 240, 2 + 8 + 128 + 32);
  }
}

class Card extends Entity {
  var card: Int;
  override public function begin() {
    pos.x = args[0];
    pos.y = args[1];
    card = args[2];
    draw();
  }

  function drawType(y, col, fill, type) {
    var x = 60;
    var color = C.COLORS[col];
    if (type == 0) {
      if (fill == 0) gfx.line(2, color).rect(x-10,y-10,20,20).line(null);
      else if (fill == 1) gfx.fill(color).line(2, color).rect(x-10,y-10,20,20).line(null);
      else if (fill == 2) {
        gfx.line(2, color).rect(x-10,y-10,20,20);
        gfx.mt(x-10,y-6).lt(x+10, y-6).mt(x-10,y-2).lt(x+10, y-2);
        gfx.mt(x-10,y+2).lt(x+10, y+2).mt(x-10,y+6).lt(x+10, y+6);
      }
    } else if (type == 1) {
      if (fill == 0) gfx.line(2, color).circle(x,y,10);
      else if (fill == 1) gfx.fill(color).line(2, color).circle(x,y,10);
      else if (fill == 2) {
        gfx.line(2, color).circle(x,y,10);
        gfx.mt(x-7,y-6).lt(x+7, y-6).mt(x-10,y-2).lt(x+10, y-2);
        gfx.mt(x-10,y+2).lt(x+10, y+2).mt(x-7,y+6).lt(x+7, y+6);

      }
    } else if (type == 2) {
      if (fill == 0) gfx.line(2, color).mt(x-11.547,y+6.666).lt(x,y-13.333).lt(x+11.547,y+6.666);
      else if (fill == 1) gfx.fill(color).line(2, color).mt(x-11.547,y+6.666).lt(x,y-13.333).lt(x+11.547,y+6.666);
      else if (fill == 2) {
        gfx.line(2, color).mt(x-11.547,y+6.666).lt(x,y-13.333).lt(x+11.547,y+6.666).line(null);
        gfx.line(2, color).mt(x-4,y-6).lt(x+4, y-6);
        gfx.mt(x-7,y-2).lt(x+7, y-2).mt(x-9,y+2).lt(x+9, y+2);
      }
    }
  }

  function draw() {
    var count = card & 3;
    var type = (card >> 2) & 3;
    var color = (card >> 4) & 3;
    var fill = (card >> 6) & 3;
    trace(card,count,type,color, fill);

    gfx.line(2, 0xCCCCCC).rect(0, 0, 120, 120);

    switch(count) {
      case 0:
        drawType(60, color, fill, type);
      case 1:
        drawType(45, color, fill, type);
        drawType(75, color, fill, type);
      case 2:
        drawType(30, color, fill, type);
        drawType(60, color, fill, type);
        drawType(90, color, fill, type);
      default:
    }
  }
}
