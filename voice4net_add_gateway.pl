#!/usr/bin/perl

#script invocation
#perl /usr/share/freeswitch/scripts/voice4net_add_gateway.pl --gateway-name='testdemo' --proxy='abc.example.com' --from-user='fromuser' --username='username' --password='password' --confpath='/tmp/'

use strict;
use warnings;
use Getopt::Long;

my $gateway_name;
my $proxy;
my $from_user;
my $username;
my $password;
my $config_path;

GetOptions(
   'gateway-name=s'      => \$gateway_name,
   'proxy=s'             => \$proxy,
   'from-user=s'         => \$from_user,
   'username=s'          => \$username,
   'password=s'      	 => \$password,
   'confpath=s'          => \$config_path
);

if ( ! $gateway_name || ! $proxy || ! $from_user || ! $username || ! $password) {
  return -1;
}

if (! $config_path)
{
	$config_path = "/etc/freeswitch/";
}

my $gateway_template = &get_gateway_template;

$gateway_template =~ s/__GATEWAY_NAME__/$gateway_name/g;
$gateway_template =~ s/__PROXY__/$proxy/g;
$gateway_template =~ s/__FROM_USER__/$from_user/g;
$gateway_template =~ s/__USERNAME__/$username/g;
$gateway_template =~ s/__PASSWORD__/$password/g;

my $new_gateway_file_name = $config_path . '/sip_profiles/external/' . $gateway_name . '.xml';

my $fh;

open($fh,'>',$new_gateway_file_name);
if ( ! $fh ) {
	return -1;
}

print $fh $gateway_template;
close($fh);

system("chown freeswitch:freeswitch ".$new_gateway_file_name);


sub get_gateway_template {
my $templ = <<ENDUSERTEMPLATE;
<include>
   <gateway name="__GATEWAY_NAME__">
     <param name="proxy" value="__PROXY__"/>
     <param name="register" value="true"/>
     <param name="caller-id-in-from" value="true"/> 
	 <param name="from-user" value="__FROM_USER__"/>
     <param name="username" value="__USERNAME__"/>
     <param name="password" value="__PASSWORD__"/>
   </gateway>
</include>
ENDUSERTEMPLATE

	return $templ;
}
