#!/usr/bin/perl -w

use File::Tail;
use DBI;
use URI;
use Getopt::Long;
use threads;
use threads::shared;
use strict;

our %opts = ();

# Set default options
$opts{squidlog} = '/var/log/squid3/access.log';
$opts{squidguardlog} = '/var/log/squidGuard/deny.log';
$opts{squid} = 1;
$opts{squidguard} = 0;
$opts{debug} = 0;
$opts{dbhost} = 'localhost';
$opts{dbname} = 'aron';
$opts{dbuser} = 'aron';
$opts{dbpass} = 'CHANGE';

# get command line arguments
GetOptions(
    "debug=i"            => \$opts{debug},
    "squidlog=s"         => \$opts{squidlog},
    "squidguardlog=s"    => \$opts{squidguardlog},
    "squid!"             => \$opts{squid},
    "squidguard!"        => \$opts{squidguard},
    "dbhost=s"           => \$opts{dbhost},
    "dbname=s"           => \$opts{dbname},
    "dbpass=s"           => \$opts{dbpass}
);

# Disable output buffering
select(STDOUT);
$| = 1;
select(STDERR);
$| = 1;

open STDERR, '>&STDOUT';

# Set process name
$0 = 'logfile-daemon_mysql.pl';

# Get hostname
our $host = `hostname`;
chomp($host);

### Subroutines

# Print messages on stderr
# for debuging purpose
sub printlog {
    my $msg = shift;
    print "$msg\n";
    return;
}

# Connect to the database
sub db_connect {
    my $dbh = DBI->connect("DBI:mysql:database=$opts{dbname};host=$opts{dbhost}",
                  $opts{dbuser}, $opts{dbpass}, {RaiseError => 1});
    die "Couldn't connect to database\n" unless ($dbh);
    return $dbh;
}

# escape chars for MySQL queries
sub mysql_escape {
    my $string = shift;
    $string =~ s|'|\\'|g;
    return $string;
}

# log squid access
sub squid_log {

    my $logfile = shift;

    printlog("squid_log thread connecting to database") if ($opts{debug} ge 1);
    my $dbh = db_connect;
    # Open log file

    printlog("opening squid log file") if ($opts{debug} ge 1);
    my $tail = File::Tail->new(name=>$logfile, maxinterval=>15);

    while (defined(my $line=$tail->read)){
        my ($timestamp, $response_time, $client_ip, $status, $reply_size,
            $request_method, $url, $username, $server, $mime_type) = split /\s+/, $line;
        my ($squid_status, $http_status) = split /\//, $status;
        my ($squid_connect, $server_ip) = split /\//, $server;

        # Skip stats requested by squidclient
        next if ($url =~ m/^cache_object:/);

        my $domain;
        if ($request_method eq 'CONNECT'){
            ($domain,undef) = split /:/, $url;
        }
        else{
            my $uri = URI->new($url);
            $domain = mysql_escape($uri->host);
        }

        # MySQL escape
        # Shouldn't be needed, but just in case logs contains junk
        $timestamp      = mysql_escape($timestamp);
        $response_time  = mysql_escape($response_time);
        $client_ip      = mysql_escape($client_ip);
        $squid_status   = mysql_escape($squid_status);
        $http_status    = mysql_escape($http_status);
        $reply_size     = mysql_escape($reply_size);
        $request_method = mysql_escape($request_method);
        $url            = mysql_escape($url);
        $username       = mysql_escape($username);
        $squid_connect  = mysql_escape($squid_connect);
        $server_ip      = mysql_escape($server_ip);
        $mime_type      = mysql_escape($mime_type);

        printlog("New access_log entry:\ntimestamp: $timestamp\nresponse_time: $response_time\n".
                 "client_ip: $client_ip\nsquid_status: $squid_status\nhttp_status: $http_status\n".
                 "reply_size: $reply_size\nrequest_method: $request_method\nurl: $url\n".
                 "username: $username\nsquid_connect: $squid_connect\n".
                 "server_ip: $server_ip\nmime_type: $mime_type\n\n") if ($opts{debug} ge 2);

        my $q = "INSERT INTO aron.statistics_plog ".
                "(proxy_host, timestamp, response_time, client_ip, squid_status, http_status, ".
                "reply_size, request_method, url, domain, username, squid_connect, server_ip, mime_type)".
                " VALUES('$host', '$timestamp','$response_time','$client_ip','$squid_status','$http_status',".
                "'$reply_size','$request_method','$url','$domain','$username','$squid_connect','$server_ip','$mime_type')";

        my $qh = $dbh->prepare($q);
        $qh->execute or exit(1);
    }
}

# log squid access
sub squidguard_log {

    my $logfile = shift;

    printlog("squidguard_log thread connecting to database") if ($opts{debug} ge 1);
    my $dbh = db_connect;
    # Open log file
    printlog("opening squidGuard log file") if ($opts{debug} ge 1);
    my $tail = File::Tail->new(name=>$logfile, maxinterval=>15);

    while (defined(my $line=$tail->read)){
        my ($date_day, $date_time, undef, $category, $url, $client_ip, $username) = split /\s+/, $line;
        # Clean some values
        $category =~ m/default\/(\w+)/;
        $category = $1;
        $client_ip =~ s/\/\-$//;

        my $uri = URI->new($url);
        my $domain = mysql_escape($uri->host);

        # MySQL escape
        $date_day  = mysql_escape($date_day);
        $date_time = mysql_escape($date_time);
        $category  = mysql_escape($category);
        $url       = mysql_escape($url);
        $client_ip = mysql_escape($client_ip);
        $username  = mysql_escape($username);

        printlog("New deny_log entry:\ndate: $date_day\ntime: $date_time\ncategory: $category\n".
                 "client_ip: $client_ip\nurl: $url\nusername: $username\n\n") if ($opts{debug} ge 2);

        my $q = "INSERT INTO aron.deny_log ".
                "(proxy_host, date_day, date_time, category, client_ip, url, domain, username)".
                " VALUES('$host', '$date_day','$date_time','$category','$client_ip','$url','$domain','$username')";

        my $qh = $dbh->prepare($q);
        $qh->execute;
    }
}

printlog("Starting log monitoring threads") if ($opts{debug} ge 1);
my $thr1 = threads->create('squid_log', $opts{squidlog}) if ($opts{squid});
my $thr = 1;
if ($opts{squidguard}){
    my $thr2 = threads->create('squidguard_log', $opts{squidguardlog}) if ($opts{squidguard});
    $thr++;
}

while (scalar(threads->list(threads::running)) ge $thr){
    sleep(5);
}

die "At least one thread died\n";
