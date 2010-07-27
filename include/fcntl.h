;; File control.

; open :: *Char pathname -> Int flags -> (Fd fd|-Error)
; close :: Fd fd -> Int flags -> (Int 0|-Error)

; read  :: Fd fd -> *Mem buf   -> Int size   -> (Int size  |-Error)
; write :: Fd fd -> *Mem buf   -> Int size   -> (Int size  |-Error)
; seek  :: Fd fd -> Int offset -> Int whence -> (Int offset|-Error)

O_NONE     = 0
O_RD       = 1
O_RDONLY   = O_RD
O_WR       = 2
O_WRONLY   = O_WR
O_RDWR     = O_RD or O_WR

O_APPEND   = 
O_TRUNK    = 

O_NONBLOCK = 

O_ASYNC    = 
O_RSYNC    = 
O_DSYNC    = 
O_SYNC     = 

O_CREAT    = 
O_DELET    = 

O_EXCL     = 
O_NOFOLLOW = 

; Only allow writes to be the same size as the read
O_SAMESIZE = 

S_IFMT     = 0 ; ???
; Only used for O_CREAT
O_DIR      = 10000h ; 000100
S_IFDIR    = O_DIR
O_FILE     = 20000h
S_IFREG    = O_FILE
O_LINK     = 30000h
S_IFLNK    = O_LINK
O_PIPE     = 40000h
S_IFIFO    = O_PIPE
O_SOCK     = 50000h
S_IFSOCK   = O_SOCK
O_BLOCK    = 60000h
S_IFBLK    = O_BLOCK
O_CHAR     = 70000h
S_IFCHR    = O_CHAR
O_DOOR     = 80000h
S_IFDR     = O_DOOR
O_SEMAPH   = 90000h
S_IFSEM    = O_SEMAPH



; File mode bits:
S_ISUID    = 0
S_ISGID    = 0
S_ISVTX    = 0

S_IRWXU    = 700o
S_IRUSR    = 400o
S_IWUSR    = 200o
S_IXUSR    = 100o

S_IRWXG    = 70o
S_IRGRP    = 40o
S_IWGRP    = 20o
S_IXGRP    = 10o

S_IRWXO    = 7o
S_IROTH    = 4o
S_IWOTH    = 2o
S_IXOTH    = 1o
; vim: ts=8 sw=8 syn=fasm
