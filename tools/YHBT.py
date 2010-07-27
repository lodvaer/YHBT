#!/usr/bin/env python
# vim: sw=4 ts=4 et smarttab encoding=UTF-8

from __future__ import print_function
import sys, subprocess, shlex
from copy import deepcopy

BLACK, R, G, Y, B, M, C = ["\x1b[3"+str(x)+"m" for x in range(0, 7)]
N = "\x1b[0m"


class Regs(object):
    valids = (['rax', 'rbx', 'rcx', 'rdx', 'rdi', 'rsi', 'rbp'] +
              ['r' + str(i) for i in range(8, 16)] + ['*'])
    def __init__(self, regs, parent=None):
        if type(regs) == type(set()):
            self.regs = regs
        elif type(regs) == type(""):
            self.regs = set([x.strip() for x in regs.split(",")
                                        if x.strip() != ''])
        else:
            raise Exception("Unexpected regs type " + str(type(regs)) +
                            " for regs " + str(regs))
        for r in self.regs:
            if r not in self.valids:
                print(parent.file if parent else "")
                raise Exception("Invalid register " + r)
    def __str__(self):
        if '*' in self.regs:
            return '*'
        x = [r for r in self.regs]
        x.sort(lambda x, y: cmp(self.valids.index(x), self.valids.index(y)))
        return ', '.join(x)
    def __eq__(self, x):
        assert isinstance(x, Regs)
        return str(self) == str(x)
    def __ne__(self, x):
        return not (self == x)
    def __repr__(self):
        return "Regs(\"" + str(self) + "\")"
    def __len__(self):
        return len(self.regs)
    def __add__(self, y):
        assert isinstance(y, Regs)
        return Regs(self.regs | y.regs)
    def __sub__(self, y):
        assert isinstance(y, Regs)
        if '*' in y.regs:
            return Regs(set([]))
        return Regs(self.regs - y.regs)

# TODO: Full blown type handling.
class Subtype(object):
    def __init__(self, type):
        self.type = type
    def __str__(self):
        return self.type
class Type(object):
    def __init__(self, type):
        self.type = [Subtype(x.strip()) for x in type.split("->")
                                        if x.strip() != '']
    def __str__(self):
        return " -> ".join(str(t) for t in self.type)
    def __len__(self):
        return len(self.type)

class Proc(object):
    def __init__(self, parent, title, desc, file, line, cur):
        self.aliases = []
        self.parent      = parent
        self.title       = title
        self.description = desc
        self.file        = file
        self.line        = line

        if ':' in cur:
            cur[':'] = Type(cur[':'])
        else:
            cur[':'] = Type("")
        if '=' in cur:
            self.aliases += [x.strip() for x in cur['='].split(',')]
        if '-' in cur:
            cur['-'] = Regs(cur['-'], self)
        else:
            cur['-'] = Regs("*")
        if '+' in cur:
            cur['+'] = Regs(cur['+'])
        else:
            cur['+'] = Regs("")
        if '.' in cur:
            cur['.'] = map(lambda x: x.strip(), cur['.'].split(','))
        else:
            cur['.'] = []
        if ' ' not in cur:
            cur[' '] = ''

        self.cur      = cur
        self.full     = self.cur[' ']
        self.type     = self.cur[':']
        self.uses     = self.cur['.']
        self.keepregs = self.cur['+']
        self.useregs  = self.cur['-']
    def get_consumption(self, past=[]):
        rs = deepcopy(self.useregs)
        for p in self.uses:
            if p not in past:
                if p not in self.parent.procs:
                    raise Exception("Proc " + self.title + " refers to"+
                                    " nonexisting proc " + p)
                rs += self.parent.procs[p].get_consumption(past + [self.title])
        rs = rs - self.keepregs
        return rs

    def prettyprint(self, file = False, full=False):
        E = N + "\n"
        o = ""
        o += M + self.title + N + ":"
        o += E + ";!\t" + self.description
        if file:
            o += E + "; FILE\t" + G + self.file + N + ":" + R + str(self.line)
        if self.type:
            o += E + ";:\t" + C + str(self.type)
        if len(self.keepregs) > 0:
            o += E + ";+\t" + G + str(self.keepregs)
        if len(self.useregs - self.keepregs) > 0:
            o += E + ";-\t" + R + str(self.useregs)
        if (self.useregs - self.keepregs) != self.get_consumption():
            o += E + ";- TOT:\t" + R + str(self.get_consumption())
        if full and self.aliases:
            o += E + ";=\t" + M + ", ".join(self.aliases)
        if full and self.full.strip():
            o += E + "; " + Y + (E + "; " + Y).join(self.full.strip().split('\n'))
        return o + N

    def __str__(self):
        return self.prettyprint()

class YHBTDoc(object):
    def _titlify(self, str, clas, ctx):
        def f(str):
            if clas == '':
                return str
            return clas+'.'+str
        if str[0:4] == "proc":
            return f(str.split(',')[1].strip())
        if str[0:7] == "intproc":
            return f(str[8:].split(',')[0].strip())
        if str[0:5] == "macro" or str[0:5] == "class":
            return str[6:].split(" ")[0]
        if len(str) > 0 and str[-1] == ':':
            return f(str.strip()[:-1])
        raise Exception, "Couldn't find the name of \"" + str + "\", " + repr(ctx)
    def __init__(self):
        _ = subprocess.Popen(
                shlex.split("find . -iname '*.asm' -print0 -o -iname '*.h' -print0"),
                stdout=subprocess.PIPE)
        self.files  = _.stdout.read().split('\0')
        self.procs  = {} # Map (String procname) Proc
        self.fprocs = {} # Map (String file) (Map (String procname=) Proc)
        self.fdocs  = {} # Map (String filename) (String file level documentation)

        ctx = ("", "")
        for f in self.files:
            if f == '': continue
            lines = map(lambda x: x.strip(), open(f).read().split('\n'))
            comment = False
            clas = ""
            desc = ""
            cur = {}
            lnum = 0
            for l in lines:
                didit = False
                ctx = (f, lnum+1)
                if l[0:2] == ";!": # Start of a comment block
                    desc  = l[2:].strip()
                    comment = True
                if comment == True and l[0:1] != ';': # End of a comment block
                    comment = False
                    titles = [self._titlify(l, clas, ctx)]
                    cur["file"] = f
                    proc = Proc(self, titles[0], desc, f, lnum, cur)
                    titles += proc.aliases
                    [self.procs.__setitem__(title, proc) for title in titles]
                    self.fprocs.setdefault(f, {})[titles[0]] = proc
                    cur = {}
                    didit = True
                if comment == True: # Add to a comment block.
                    if len(l) > 2:
                        cur[l[1]] = (cur.get(l[1], "") + l[2:] + '\n')
                if l[0:2] == ";;":  # File level comment
                    self.fdocs[f] = self.fdocs.get(f, "") + l[2:] + '\n'
                if l[0:6] == "class ": # The class we're in.
                    clas = l[6:].strip()
                if l[0:8] == "quaject ": # For naming purposes a quaject is a class.
                    clas = l[8:]
                if didit == False and (l[0:5] == "proc " or
                                       l[0:8] == "intproc ")\
                                  and 'IGNORE' not in l:
                        print(repr(ctx)+": "+l+": Lacking doc.", file=sys.stderr)
                if l[0:8] == "endclass" or l[0:10] == "endquaject":
                    clas = ""
                lnum += 1
            if f not in self.fdocs:
                print("File", f, "lacking fdoc.")
            if cur != {} or comment != False:
                print(repr(ctx)+": Unended comment block.", file=sys.stderr)
