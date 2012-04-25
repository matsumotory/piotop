#!/usr//bin/perl
#############################################################################################
#
#   Process I/O Statistics Investigating Tool
#       Copyright (C) 2012 MATSUMOTO, Ryosuke
#
#   This Code was written by matsumoto_r                 in 2012/04/15 -
#
#   Usage:
#       /usr/local/sbin/piotop.pl
#
#############################################################################################
#
# Change Log
#
# 2012/04/10 matsumoto_r first release 0.01
# 2012/04/15 matsumoto_r System::Proc::Stat Class create 1.00
#
#############################################################################################

use strict;
use warnings;
use lib "/usr/local/lib/myperl_lib";
use System::Proc;
use File::Spec;
use File::Basename;
use bigint;
use Getopt::Long;

our $VERSION    = '1.00';
our $SCRIPT     = basename($0);

$| = 1;

die "kernel not found io support\n" if !-f "/proc/self/io";

my ($lines, $sortkey, $sortorder, $showzero, $count, $interval, $batch);

GetOptions(

    "--line=i"          =>  \$lines, 
    "--interval=i"      =>  \$interval, 
    "--sort=s"          =>  \$sortorder, 
    "--count=i"         =>  \$count, 
    "--nozero"          =>  \$showzero,
    "--help"            =>  \&help,
    "--version"         =>  \&version,
);

$interval    = (!defined $interval || $interval < 0)            ?   3   :   $interval; 
$count       = (!defined $count || $count <= 0)                 ?   0   :   $count;
$sortkey     = (!defined $sortorder || $sortorder ne "read")    ?   3   :   2;
$lines       = (!defined $lines || $lines <= 0)                 ?   40  :   $lines;

our $PROC = System::Proc->new(
   debug           =>  0,
   info            =>  0,
   warn            =>  0,
   error           =>  0,
   irc_owner       =>  $SCRIPT,
   tool_name       =>  $SCRIPT,
   log_file        =>  "/tmp/$SCRIPT-$ENV{USER}.log",
   pid_file        =>  "/tmp/$SCRIPT.pid",
   lock_file       =>  "/tmp/$SCRIPT.lock",
   syslog_type     =>  $SCRIPT,
);

our $PHEADER = sprintf("%s %-5s %-16s %-12s %-12s %-16s %-20s%s", 
                    "\e[1m",
                    "pid", 
                    "state", 
                    "read", 
                    "write", 
                    "command",
                    "cwd_path",
                    "\n\e[0m");

$SIG{INT}  = sub { $PROC->TASK_SIGINT };
$SIG{TERM} = sub { $PROC->TASK_SIGTERM };

$PROC->set_lock;
$PROC->make_pid_file;

my $counter  = 0;
my $current  = 0;
my %old      = ();

while ($count == 0 || $counter < $count) {
    
    if ($counter == 0) {
        print `clear` . "-- Every $interval sec --\n" . `uptime`;
        print $PHEADER;
        %old = %{&get_current_proc_info};
        sleep $interval;
    }

    $counter++;
    $current = &get_current_proc_info;
    &print_proc($sortkey, $lines, $current, \%old, $showzero);
    %old = %$current;

    sleep $interval;
}

exit 0;

#############################################################################################
#
# Sub Routines
#
#############################################################################################

sub get_current_proc_info {

    my @pids = $PROC->get_pid_list;
    my %current_data = ();

    foreach my $pid (@pids) {
	    chomp($pid);
        next if !-d "/proc/$pid";
	    my $io_data  = $PROC->get_io_by_pid($pid);
	    my $cmd_data = $PROC->get_cmdname_by_pid($pid);
	    my $exe_path = $PROC->get_exe_by_pid($pid);
	    my $cwd_path = $PROC->get_cwd_by_pid($pid);

        $cmd_data->{envID} = "nothing" if !defined $cmd_data->{envID} || $cmd_data->{envID} !~ /^\d+$/;
	    $current_data{$pid} = "$cmd_data->{Name}\0$cmd_data->{State}\0$io_data->{read_bytes}\0$io_data->{write_bytes}\0_exe_path\0$cmd_data->{envID}\0$cwd_path";
    }

    return \%current_data;
}


sub print_proc {

    my ($sort_key, $lines, $current_data, $old_data, $showzero) = @_;

    my %datalist;
    my %cur_datalist;
    my %old_datalist;

    foreach my $pid (keys %{$old_data}) {
        next if !defined $old_data->{$pid};
	    my (@data) = split(/\0/, $old_data->{$pid});
	    @{$old_datalist{$pid}} = @data;
    }

    foreach my $pid (keys %{$current_data}) {
        next if !defined $current_data->{$pid};
	    my (@data) = split(/\0/, $current_data->{$pid});
	    @{$cur_datalist{$pid}} = @data;
        next if !defined $cur_datalist{$pid}[0] || !defined $old_datalist{$pid}[0];
	    if ($cur_datalist{$pid}[0] eq $old_datalist{$pid}[0]) {
	        $datalist{$pid}[0] = $cur_datalist{$pid}[0];
	        $datalist{$pid}[1] = $cur_datalist{$pid}[1];
	        $datalist{$pid}[2] = $cur_datalist{$pid}[2] -  $old_datalist{$pid}[2];
	        $datalist{$pid}[3] = $cur_datalist{$pid}[3] -  $old_datalist{$pid}[3];
	        $datalist{$pid}[4] = $cur_datalist{$pid}[4];
	        $datalist{$pid}[5] = ($cur_datalist{$pid}[5] =~ /^\d+$/) ?   $cur_datalist{$pid}[5] :   "nothing";
	        $datalist{$pid}[6] = $cur_datalist{$pid}[6];
	    }
    }

    my ($sort1, $sort2) = ($sort_key == 2) ?   (2,3)   :   (3,2);

    print `clear` . "-- Every $interval sec --\n" . `uptime`;
    print $PHEADER;

    my $count = 0;

    foreach my $pid (sort {$datalist{$b}[$sort1] <=> $datalist{$a}[$sort1] or $datalist{$b}[$sort2] <=> $datalist{$a}[$sort2]} keys %datalist) {
	    $count++;
        my $color_head  = "\e[0m";
        my $color_tail  = "\e[0m";

        my $state       = $datalist{$pid}[1];
        my $read        = $datalist{$pid}[2];
        my $write       = $datalist{$pid}[3];
        my $command     = $datalist{$pid}[0];
        my $cwd_path    = $datalist{$pid}[6];

	    printf("%s %-5d %-16s %-12s %-12s %-16s %-20s%s\n", 
            $color_head,
            $pid, 
            $state, 
            $PROC->byte_to_bps($read, $interval), 
            $PROC->byte_to_bps($write, $interval), 
            $command,
            $cwd_path,
            $color_tail) if $showzero == 0 || $read != 0 || $write != 0;

	    return if $count >= $lines;
    }
}

sub help {
    print <<USAGE;

    usage: ./$SCRIPT [--line|-l LINE] [--interval|-i INTERVAL] [--sortorder|-s SORT] [--count|-c COUNT] [--zero|-z]

        -l, --line            output lines (default 20)
        -i, --interval        check interval (default 3)
        -s, --sort            sort order: read, write (default read)
        -c, --count           count (default no limit)
        -z, --nozero          don't print zero value
        -h, --help            display this help and exit
        -v, --version         display version and exit

USAGE
    exit(1);
}

sub version {

    print <<VERSION;

    Version: $SCRIPT-$VERSION

VERSION
    exit(1);

}
