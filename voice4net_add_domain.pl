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

unless ( -d $recordings_path ) {
	unless(mkdir $recordings_path) {
        die "\nUnable to create $recordings_path\n";
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
my $dialplan_files = $config_path . '/dialplan/' . $domain;
my $registered_users_file = $dialplan_files . '/00_accept_registered_users.xml';

copy($dir . '/dialplan/default.xml', $dialplan_file);
copy($dir . '/directory/default.xml', $directory_file);
system("cp " . $dir . '/dialplan/default/*.xml'. ' '. $dialplan_files);

system("sed -i -e 's/default/" . $domain . "/g' " . $dialplan_file);
system("sed -i -e 's/\"default\"/\"" . $domain . "\"/g' -e 's/\"default\\//\"" . $domain . "\\//g' -e 's/\$\${domain}/" . $domain . "/g' " . $directory_file);
system("sed -i -e 's/park_reason=new_call/park_reason=" . $park_reason . "/g' " . $registered_users_file);

system("chown -R freeswitch:freeswitch ".$dialplan_path);
system("chown -R freeswitch:freeswitch ".$directory_path);
system("chown -R freeswitch:freeswitch ".$recordings_path);

generate_virtual_directory_files("http");
generate_virtual_directory_files("https");

system("/etc/init.d/apache2 reload");

sub generate_virtual_directory_files {
	my $protocol = $_[0];
	my $virtual_directory_template = "";
	my $virtual_directory_file = "";
	my @string_array = split(/\//,$recordings_path);
	my $domain_name = $string_array[-1];

	if ($protocol eq "http")
	{
		$virtual_directory_template = &get_new_http_virtual_directory_template;
		$virtual_directory_file = '/etc/apache2/sites-available/' . $domain . '_http_recordings.conf';	
	}
	else
	{
		$virtual_directory_template = &get_new_https_virtual_directory_template;
		$virtual_directory_file = '/etc/apache2/sites-available/' . $domain . '_https_recordings.conf';
	}

	$virtual_directory_template =~ s/__DOMAIN_NAME__/$domain_name/g;
	$virtual_directory_template =~ s/__RECORDINGS_PATH_FOR_DOMAIN__/$recordings_path/g;

	my $fh;

	open($fh,'>',$virtual_directory_file);
	if ( ! $fh ) {
		return -1;
	}

	print $fh $virtual_directory_template;
	close($fh);

	system("ln -r -s ".$virtual_directory_file.' /etc/apache2/sites-enabled/');
}

sub get_new_http_virtual_directory_template {
my $templ = <<ENDUSERTEMPLATE;
<VirtualHost *:80>        
	Alias "/CallRecordings/__DOMAIN_NAME__" "__RECORDINGS_PATH_FOR_DOMAIN__"
</VirtualHost>
ENDUSERTEMPLATE

	return $templ;
}

sub get_new_https_virtual_directory_template {
my $templ = <<ENDUSERTEMPLATE;
<VirtualHost *:443>        
	Alias "/CallRecordings/__DOMAIN_NAME__" "__RECORDINGS_PATH_FOR_DOMAIN__"
</VirtualHost>
ENDUSERTEMPLATE

	return $templ;
}
