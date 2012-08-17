## What's piotop.pl
device I/O per process monitoring tool.

## How to use

* command

        # ./iotop

* output I/O list per 3 seconds.

        -- Every 3 sec --
         14:55:06 up 3 days,  9:05,  5 users,  load average: 1.03, 1.06, 0.82
         pid   state            read         write        command          cwd_path            
         3292  D (disk sleep)   0bps         16Mbps       dd               /root               
         32373 S (sleeping)     0bps         746Kbps      btrfs-endio-wri  /                   
         1940  S (sleeping)     0bps         10Kbps       flush-btrfs-4    /                   
         892   S (sleeping)     0bps         0bps         sedispatch       /                   
         882   S (sleeping)     0bps         0bps         acpid            /       

* usage

            usage: ./piotop.pl [--line|-l LINE] [--interval|-i INTERVAL] [--sortorder|-s SORT] [--count|-c COUNT] [--zero|-z]
        
                -l, --line            output lines (default 20)
                -i, --interval        check interval (default 3)
                -s, --sort            sort order: read, write (default read)
                -c, --count           count (default no limit)
                -z, --nozero          don't print zero value
                -h, --help            display this help and exit
                -v, --version         display version and exit

