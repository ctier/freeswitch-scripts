#!/usr/bin/perl

# To install dependencies:
# cpan Getopt::Long
# cpan Git::Repository

use strict;
use warnings;
use Getopt::Long;
use Git::Repository;
use File::Copy;
use File::Path;

my $config_path;
my $domain;
my $park_reason;

GetOptions(
   'domain=s'               => \$domain,
   'confpath=s'             => \$config_path,
   'park-reason=s'          => \$park_reason
);

if ( ! $domain ) {
  $domain = 'default';
}

if ( ! $config_path ) {
  $config_path = '/etc/freeswitch/';
}

if ( ! $park_reason ) {
  $park_reason = 'new_call';
}

unless ( -d $config_path ) {
	die "Configuration path '$config_path' does not exist.\n";
}

my $dialplan_path = $config_path . '/dialplan/' . $domain;
unless ( -d $dialplan_path ) {
	unless(mkdir $dialplan_path) {
        die "\nUnable to create $dialplan_path\n";
    }
}

my $directory_path = $config_path . '/directory/' . $domain;
unless ( -d $directory_path ) {
	unless(mkdir $directory_path) {
        die "\nUnable to create $directory_path\n";
    }
}

my $url = 'https://github.com/voice4net/freeswitch-config.git';
my $dir = '/usr/src/freeswitch-config/';

if ((-d $dir) && (-d $dir . '.git')) {
	my $r = Git::Repository->new( git_dir => $dir . '.git');
	$r->run( pull => $url);
}
else{
	rmtree $dir;
	Git::Repository->run( clone => $url ,$dir );
}

my $dialplan_file = $config_path . '/dialplan/' . $domain . '.xml';
my $directory_file = $config_path . '/directory/' . $domain . '.xml';
my $registered_users_file = $config_path . '/dialplan/' . $domain . '/00_accept_registered_users.xml';

copy($dir . '/dialplan/default.xml', $dialplan_file);
copy($dir . '/directory/default.xml', $directory_file);
copy($dir . '/dialplan/default/00_accept_registered_users.xml', $registered_users_file);

system("sed -i -e 's/default/" . $domain . "/g' " . $dialplan_file);
system("sed -i -e 's/\"default\"/\"" . $domain . "\"/g' -e 's/\"default\\//\"" . $domain . "\\//g' -e 's/\$\${domain}/" . $domain . "/g' " . $directory_file);
system("sed -i -e 's/park_reason=new_call/park_reason=" . $park_reason . "/g' " . $registered_users_file);

my $uid = getpwnam 'freeswitch';
my $gid = getgrnam 'freeswitch';

chown $uid, $gid, $dialplan_path;
chown $uid, $gid, $directory_path;
chown $uid, $gid, $dialplan_file, $registered_users_file;
chown $uid, $gid, $directory_file;
