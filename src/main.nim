
import std/[random,asyncdispatch,exitprocs]
from globals import nil
import connection,iran_server,foreign_server


randomize()
globals.init()

#full reset iptables at exit (if the user allowed)
if globals.multi_port and globals.reset_iptable and globals.mode == globals.RunMode.iran:
    addExitProc do():
        globals.resetIptables() 
    setControlCHook do(){.noconv.}:
        quit() # that will call above hook


#increase systam maximum fds to be able to handle more than 1024 cons (650000 for now)
when defined(linux) and not defined(android):
    import std/[posix,os,osproc]
    if not globals.keep_system_limit:
        if not isAdmin():
            echo "Please run as root. or start with --keep-os-limit "
            quit(-1)

        if globals.disable_ufw:
            discard 0 == execShellCmd("sudo ufw disable")
        try:    
           
            discard 0 == execShellCmd("sysctl -w fs.file-max=100000")
            var limit = RLimit(rlim_cur:65000,rlim_max:66000)
            assert 0 == setrlimit(RLIMIT_NOFILE,limit)
        except : # try may not be able to catch above exception, anyways
            echo getCurrentExceptionMsg()
            echo "Could not increase system max connection (file descriptors) limit."
            echo "Please run as root. or start with --keep-os-limit "
            quit(-1)



#idle connection removal controller (yes, os already has that but we want more control)
asyncCheck startController()


if globals.mode == globals.RunMode.iran:
    asyncCheck iran_server.start()
else:
    asyncCheck foreign_server.start()

runForever()