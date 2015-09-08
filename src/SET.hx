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
  var cursor: Cursor;
  public var cards: Array<Card>;
  var deck: Array<Int>;
  public var mark: Array<Mark>;
  var grave: Array<Card>;
  static public function main() {
    Micro.baseColor = C.black;
    new SET("SET", "");
  }

  override public function begin() {
    var a = 8;

    cursor = new Cursor();
    cards = new Array<Card>();
    mark = new Array<Mark>();
    grave = [null, null, null];

    deck = new Array<Int>();
    for (c in 0...3) {
      for (t in 0...3) {
        for (f in 0...3) {
          for (n in 0...3) {
            deck.push(n + (f << 2) + (t << 4) + (c << 6));
          }
        }
      }
    }

    for (i in 0...16) {
      var c = new Card(X(i), Y(i), pick());
      cards.push(c);
    }
  }

  inline public function X(i: Int) {
    return 20 + 55 + 110*(i % 4);
  }

  inline public function Y(i: Int) {
    return 20 + 55 + 110*Std.int(i / 4);
  }

  function pick(): Int {
    var i = Std.int(Math.random()*deck.length);
    var r = deck[i];
    deck.remove(r);
    return r;
  }

  function check(): Bool {
    var types = [0,0,0];
    var colors = [0,0,0];
    var numbers = [0,0,0];
    var fills = [0,0,0];
    for (i in 0...3) {
      var card = cards[mark[i].selected].card;
      numbers[i] = card & 3;
      types[i] = (card >> 2) & 3;
      colors[i] = (card >> 4) & 3;
      fills[i] = (card >> 6) & 3;
    }

    var m1 = false;
    var m2 = false;
    var m3 = false;
    var m4 = false;
    if (numbers[0] == numbers[1] && numbers[0] == numbers[2]) m1 = true;
    if (numbers[0] != numbers[1] && numbers[0] != numbers[2] && numbers[1] != numbers[2]) m1 = true;
    if (colors[0] == colors[1] && colors[0] == colors[2]) m2 = true;
    if (colors[0] != colors[1] && colors[0] != colors[2] && colors[1] != colors[2]) m2 = true;
    if (types[0] == types[1] && types[0] == types[2]) m3 = true;
    if (types[0] != types[1] && types[0] != types[2] && types[1] != types[2]) m3 = true;
    if (fills[0] == fills[1] && fills[0] == fills[2]) m4 = true;
    if (fills[0] != fills[1] && fills[0] != fills[2] && fills[1] != fills[2]) m4 = true;
    trace(m1,m2,m3,m4);
    return m1 && m2 && m3 && m4;
  }

  override public function update() {
    if (Game.key.b1_pressed) {
      var sel = cursor.selected;
      var create = true;

      for (m in mark) {
        if (m.selected == sel) {
          mark.remove(m);
          m.remove();
          create = false;
          break;
        }
      }
      if (create) {
        var m = new Mark(X(sel), Y(sel), sel);
        mark.push(m);
        if (mark.length == 3) {
          if (check()) {
            for (i in 0...3) {
              if (grave[i] != null) grave[i].remove();
              var p = mark[i].selected;
              grave[i] = cards[p];
              grave[i].sprite.scaleX = grave[i].sprite.scaleY = 0.3;
              grave[i].pos.y = 470;
              grave[i].pos.x = 470 - 25*i;

              cards[p] = new Card(X(p), Y(p), pick());
              mark[i].remove();
            }
            mark = [];
          } else {
            for (i in 0...3) {
              mark[i].remove();
            }
            mark = [];
          }
        }
      }
    }
  }
}

class Mark extends Entity {
  static public var layer = 10;
  public var selected: Int;
  override public function begin() {
    pos.x = args[0];
    pos.y = args[1];
    selected = args[2];
    gfx.line(4, C.COLORS[3]).size(100, 100).rect(4, 4, 92, 92);
  }
}

class Cursor extends Entity {
  static public var layer = 11;

  public var selected = 4;
  override public function begin() {
    gfx.line(4, C.COLORS[4]).rect(0, 0, 100, 100);
  }

  override public function update() {
    var x = selected % 4;
    var y = Std.int(selected/4);
    // update keyboard with selected
    if (Game.key.left_pressed) x = (4 + x - 1) % 4;
    if (Game.key.right_pressed) x = (x + 1) % 4;
    if (Game.key.up_pressed) y = (4 + y - 1) % 4;
    if (Game.key.down_pressed) y = (y + 1) % 4;
    selected = x + y*4;
    // update mouse move with selected

    // update position
    pos.x = 20 + 55 + 110*(selected % 4);
    pos.y = 20 + 55 + 110*Std.int(selected / 4);
  }
}

class Card extends Entity {
  public var card: Int;
  override public function begin() {
    pos.x = args[0];
    pos.y = args[1];
    card = args[2];
    draw();
  }

  function drawType(x: Float, y: Float, col, fill, type) {
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
    gfx.size(100, 100);

    switch(count) {
      case 0:
        drawType(50, 50, color, fill, type);
      case 1:
        drawType(35, 50, color, fill, type);
        drawType(65, 50, color, fill, type);
      case 2:
        for (i in 0...3) {
          var a = 3*Math.PI/2 + i*2*Math.PI/3;
          drawType(50 + 18*Math.cos(a), 50 + 18*Math.sin(a), color, fill, type);
        }
      default:
    }
  }
}
