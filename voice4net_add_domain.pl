#!/usr/bin/perl

# To install dependencies:
# cpan Getopt::Long
# cpan Git::Repository

#script usage
#perl /usr/share/freeswitch/scripts/voice4net_add_domain.pl --domain='abc.example.com' --confpath='/etc/freeswitch/' --park-reason='new_call' --recordings-path='/var/lib/freeswitch/recordings/customer1'

use strict;
use warnings;
use Getopt::Long;
use Git::Repository;
use File::Path;
use File::Copy;

my $config_path;
my $domain;
my $park_reason;
my $recordings_path;

GetOptions(
   'domain=s'               => \$domain,
   'confpath=s'             => \$config_path,
   'park-reason=s'          => \$park_reason,
   'recordings-path=s'      => \$recordings_path
);

if ( ! $domain ) {
  $domain = 'default';
}

if ( ! $config_path ) {
  $config_path = '/etc/freeswitch/';
}

if ( ! $recordings_path ) {  
  $recordings_path = '/var/lib/freeswitch/recordings/' . $domain;
}

if ( ! $park_reason ) {
  $park_reason = 'new_call';
}

unless ( -d $config_path ) {
	die "Configuration path '$config_path' does not exist.\n";
}

my $dialplan_path = $config_path . '/dialplan/';

my $dialplan_domain_path = $dialplan_path . $domain;
unless ( -d $dialplan_domain_path ) {
	unless(mkdir $dialplan_domain_path) {
        die "\nUnable to create $dialplan_domain_path\n";
    }
}

my $dialplan_public_path = $dialplan_path . '/public/';
unless ( -d $dialplan_public_path ) {
	unless(mkdir $dialplan_public_path) {
        die "\nUnable to create $dialplan_public_path\n";
    }
}

my $directory_path = $config_path . '/directory/';

my $directory_domain_path = $directory_path . $domain;
unless ( -d $directory_domain_path ) {
	unless(mkdir $directory_domain_path) {
        die "\nUnable to create $directory_domain_path\n";
    }
}

unless ( -d $recordings_path ) {
	unless(mkdir $recordings_path) {
        die "\nUnable to create $recordings_path\n";
    }
}

my $url = 'https://github.com/voice4net/freeswitch-config.git';
my $dir = '/usr/src/freeswitch-config/';

if ((-d $dir) && (-d $dir . '.git')) {
	my $r = Git::Repository->new( git_dir => $dir . '.git');
	$r->run( pull => $url, { quiet => 1 });
}
else{
	rmtree $dir;
	Git::Repository->run( clone => $url ,$dir );
}

my $dialplan_file = $dialplan_path . $domain . '.xml';
my $directory_file = $directory_path . $domain . '.xml';
my $registered_users_file = $dialplan_domain_path . '/00_accept_registered_users.xml';

copy($dir . '/dialplan/default.xml', $dialplan_file);
copy($dir . '/directory/default.xml', $directory_file);
system("cp " . $dir . '/dialplan/default/*.xml '. $dialplan_domain_path);
system("cp -n " . $dir . '/dialplan/public/*.xml '. $dialplan_public_path);

system("sed -i -e 's/default/" . $domain . "/g' " . $dialplan_file);
system("sed -i -e 's/\"default\"/\"" . $domain . "\"/g' -e 's/\"default\\//\"" . $domain . "\\//g' -e 's/\$\${domain}/" . $domain . "/g' " . $directory_file);
system("sed -i -e 's/park_reason=new_call/park_reason=" . $park_reason . "/g' " . $registered_users_file);

system("chown -R freeswitch:freeswitch ".$dialplan_path);
system("chown -R freeswitch:freeswitch ".$directory_path);
system("chown -R freeswitch:freeswitch ".$recordings_path);