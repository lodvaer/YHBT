#!/usr/bin/env python
import fas
import sys

akeys = fas.asms.keys()
akeys.sort()

if '-h' in sys.argv or '--help' in sys.argv:
    print """
        {0} [-h|--help] [addr] [how much to display in all directions]
    """
try:
    try:
        num = int(sys.argv[2])
    except IndexError:
        num = 10
    index = int(sys.argv[1])
except ValueError:
    index = int(sys.argv[1], 16)
except IndexError:
    index = 0
    num   = 10000
try:
    index = akeys.index(index)
except ValueError:
    print str(index) + " not in addr table."
    raise SystemExit

for i in akeys[max(index - num, 0):min(index + num, len(akeys))]:
    print fas.asms[i].strip()

