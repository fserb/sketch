#!/usr/bin/python

import sys
import re

def main(args):
  prj = args[1]

  if prj.startswith('src/'):
    prj = prj[4:-3]

  params = {
    "name": prj,
    "lname" : prj.lower(),
    "bgcolor": 0x000000,
    "haxelib": [] }

  for l in file("src/" + prj + ".hx"):
    ls = l.strip()
    if not ls: continue
    if not ls.startswith("//@"): break
    p = re.findall(r"//@ ugl\.(\S+) = (\S+)$", ls)[0]
    if (p[0] in ['haxelib']):
      params[p[0]].append(p[1])
    else:
      params[p[0]] = p[1]

  params['haxelib'] = '\n'.join('<haxelib name="%s" />' % s
                                for s in params['haxelib'])
  data = PROJECT % params
  with file("project.xml", "wt") as f:
    f.write(data)


PROJECT = """
<?xml version="1.0" encoding="utf-8"?>
<project>
  <meta title="%(name)s" package="com.fserb.%(lname)s" version="1.0.0" company="Fernando Serboncini" />

  <app main="%(name)s" path="bin" file="%(name)s" swf-version="11.8" />

  <window fps="60" background="%(bgcolor)s" resizable="false" require-shaders="true" vsync="false" antialiasing="0" />
  <window width="480" height="480" unless="mobile" />
  <window orientation="landscape" fullscreen="true" if="mobile" />

  <ios devices="universal" />

  <source path="src" />

  <haxelib name="vault" />
  <haxelib name="openfl" />
  %(haxelib)s
</project>
"""

if __name__ == '__main__':
  main(sys.argv)
