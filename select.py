#!/usr/bin/python

import sys
import re

def main(args):
  prj = args[1]

  if prj.startswith('src/'):
    prj = prj[4:-3]

  params = {
    "name": prj[prj.rfind('/')+1:],
    "lname" : prj.lower(),
    "bgcolor": 0x000000,
    "width": 480,
    "height": 480,
    "orientation": "portrait",
    "assets": "",
    "defs": [],
    "haxelib": [] }

  params['debug'] = '<haxedef name="ugldebug" />'
  if len(args) >= 3:
    if args[2] == 'prod':
      params['debug'] = ''
    elif args[2] == 'debugfps':
      params['debug'] += '\n  <haxedef name="ugldebugfps" />'

  for l in file("src/" + prj + ".hx"):
    ls = l.strip()
    if not ls: continue
    if not ls.startswith("//@"): break
    try:
      p = re.findall(r"//@ ugl\.(\S+) = (\S+)$", ls)[0]
    except IndexError:
      continue
    if (p[0] in ['haxelib']):
      params[p[0]].append(p[1])
    elif p[0] == 'landscape':
      params['orientation'] = 'landscape'
    elif p[0] == 'res':
      sp = p[1].split('x', 2)
      params['width'], params['height'] = int(sp[0]), int(sp[1])
    elif p[0] == 'def':
      params['defs'].append("tabletop")
    elif p[0] == 'assets':
      params['assets'] = '<assets path="assets/%s" rename="data" />' % params['name']
    else:
      params[p[0]] = p[1]

  params['haxelib'] = '\n'.join('<haxelib name="%s" />' % s
                                for s in params['haxelib'])
  params['defs'] = '\n'.join('<haxedef name="%s" />' % x for x in params['defs'])

  data = PROJECT % params
  with file("project.xml", "wt") as f:
    f.write(data)


PROJECT = """
<?xml version="1.0" encoding="utf-8"?>
<project>
  <meta title="%(name)s" package="com.fserb.%(lname)s" version="1.0.0" company="Fernando Serboncini" />

  <app main="%(name)s" path="bin" file="%(name)s" swf-version="11.8" />

  <window fps="60" background="%(bgcolor)s" resizable="false" require-shaders="true" vsync="false" antialiasing="0" />
  <window width="%(width)d" height="%(height)d" />
  <window orientation="%(orientation)s" fullscreen="true" if="mobile" />

  <ios devices="universal" />

  <source path="src" />
  <source path="src/motion" />

  %(assets)s

  <haxelib name="vault" />
  <haxelib name="openfl" />
  <haxelib name="hxColorToolkit" />
  <haxelib name="sfxr" />
  %(haxelib)s

  %(debug)s
  %(defs)s
</project>
"""

if __name__ == '__main__':
  main(sys.argv)
