#!/usr/bin/env python
# vim: sw=4 ts=4 et smarttab encoding=UTF-8
from __future__ import print_function
import sys
from YHBT import YHBTDoc

if len(sys.argv) < 2 or '-h' in sys.argv or '-?' in sys.argv\
        or '--help' in sys.argv:
    print("Usage: doc [-h] [-f <filename>] [procname] [-u]")
    print("-h for help, -u for full documentation.")
    print("filename excludes procname, and it gives all procs with a sustring")
    print(" match per default.")
    raise SystemExit(0)

def indent(n, s):
    return '\n'.join([" "*n+x for x in s.split("\n")])

doc = YHBTDoc()
full = '-u' in sys.argv
if full:
    del sys.argv[sys.argv.index('-u')]

if '-f' in sys.argv:
    f = sys.argv[sys.argv.index('-f') + 1]
    possibles = []
    for fname in doc.fdocs:
        if f in fname:
            possibles.append(fname)
    if len(possibles) > 1:
        print("Match not found. Did you mean any of:")
        [print(p) for p in possibles]
    elif len(possibles) == 0:
        print("Match not found.")
    else:
        p = possibles[0]
        print(doc.fdocs[p])
        for proc in doc.fprocs[p]:
            print("\n", doc.fprocs[p][proc].prettyprint(full=full), sep='')

    raise SystemExit(0)


p = sys.argv[-1]
found = False
out = []
for pp in doc.procs:
    if p not in pp: continue
    found = True
    x = doc.procs[pp]
    out.append((x.file + ":" + str(x.line), x))
if not found:
    print("Proc not found. Sorry.")
else:
    out.sort(lambda x, y: cmp(x[0], y[0]))
    for o in out:
        print("\n", o[1].prettyprint(file=True, full=full), sep='')
