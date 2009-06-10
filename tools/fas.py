import os


fas = open(os.environ['HOME'] + "/prog/YHBT/kern.fas").read()

class FasError(Exception):
    pass

def byte(loc):
    return ord(fas[loc]) 
def word(loc):
    return ord(fas[loc]) + (ord(fas[loc + 1]) << 8)
def dword(loc):
    return ord(fas[loc]) + (ord(fas[loc + 1]) << 8) + \
           (ord(fas[loc + 2]) << 16) + (ord(fas[loc + 3]) << 24)
def zstr(loc):
    o = ""
    while ord(fas[loc]) != 0:
        o   = o + fas[loc]
        loc = loc + 1
    return o


header_length  = word(6)
strings        = dword(16)
strings_length = dword(20)
symbols        = dword(24)
symbols_length = dword(28)
preproc        = dword(32)
preproc_length = dword(36)
asm            = dword(40)
asm_length     = dword(44)

def asmline(loc):
    if loc == 0:
        return ""
    loc = preproc + 16 + loc
    return "\t\t" + asmseg(loc)

def asmseg(loc):
    if loc > preproc + preproc_length or fas[loc] == "\x00" or fas[loc] == ';':
        return ""
    if fas[loc] == "\x1A":
        len = byte(loc + 1)
        return " " + fas[loc + 2: loc + 2 + len] + asmseg(loc+2+len)
    if fas[loc] == ",":
        return "," + "\t" + asmseg(loc + 1)
    if fas[loc] == "\"":
        len = dword(loc + 1)
        if len > 100:
            return "Too big."
        loc = loc + 5
        return "\t\"" + fas[loc:loc + len] + "\"" + asmseg(loc + len)
    if fas[loc] in [':', '[', '(', ')', ']', '+', '-', '*', '/',\
                    '<', '>', '=', '~']:
        return " " + fas[loc] + asmseg(loc + 1)
    return "" "\tEEE\t" + fas[loc]

asm_offsets = [asm + i for i in xrange(0, asm_length, 28)][:-1]
asms = {}
for a in asm_offsets:
    pos = dword(a + 8)
    if pos not in asms:
        asms[pos] = ""
    asms[pos] = asms[pos] + hex(dword(a + 8)) + ":\t" +\
                asmline(dword(a+4)) + "\n"

