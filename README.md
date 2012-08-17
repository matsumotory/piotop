## What's piotop.pl
device I/O per process monitoring tool.

## How to use

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
