#!/usr/bin/perl

#script invocation
#perl /usr/share/freeswitch/scripts/voice4net_add_gateway.pl --gateway-name='testdemo' --proxy='abc.example.com' --register='true' --caller-id-in-from='true' --from-user='fromuser' --from-domain='abc.example.com' --extension='testdemo' --extension-in-contact='true' --sip-contact-user="testdemo" --username='username' --password='password' --confpath='/tmp/' [--park_reason='tier1fitz_new_call']

use strict;
use warnings;
use Getopt::Long;

my $gateway_name;
my $proxy;
my $register="true";
my $caller_id_in_from;
my $from_user;
my $from_domain;
my $extension;
my $extension_in_contact;
my $sip_contact_user;
my $username;
my $password;
my $park_reason;
my $config_path;

GetOptions(
   'gateway-name=s'      		=> \$gateway_name,
   'proxy=s'             		=> \$proxy,
   'register=s'          		=> \$register,
   'caller-id-in-from=s'   		=> \$caller_id_in_from,
   'from-user=s'         		=> \$from_user,
   'from-domain=s'       		=> \$from_domain,
   'extension=s'         		=> \$extension,
   'extension-in-contact=s'     => \$extension_in_contact,
   'sip-contact-user=s'		    => \$sip_contact_user,
   'username=s'          		=> \$username,
   'password=s'      	 		=> \$password,
   'park_reason=s'      	 	=> \$park_reason,
   'confpath=s'          		=> \$config_path
);

if ( ! $gateway_name || ! $proxy || ! $from_user || ! $username || ! $password) {
  return -1;
}

if (! $config_path)
{
	$config_path = "/etc/freeswitch/";
}

my $gateway_config = "<include>\n";

$gateway_config .= "\t<gateway name=\"" . $gateway_name . "\">\n";
$gateway_config .= "\t\t<param name=\"proxy\" value=\"" . $proxy . "\"/>\n";

if ($register)
{
	$gateway_config .= "\t\t<param name=\"register\" value=\"" . $register . "\"/>\n";
}

if ($caller_id_in_from)
{
	$gateway_config .= "\t\t<param name=\"caller-id-in-from\" value=\"" . $caller_id_in_from . "\"/>\n";
}

$gateway_config .= "\t\t<param name=\"from-user\" value=\"" . $from_user . "\"/>\n";

if ($from_domain)
{
	$gateway_config .= "\t\t<param name=\"from-domain\" value=\"" . $from_domain . "\"/>\n";
}

if ($extension)
{
	$gateway_config .= "\t\t<param name=\"extension\" value=\"" . $extension . "\"/>\n";
}

if ($extension_in_contact)
{
	$gateway_config .= "\t\t<param name=\"extension-in-contact\" value=\"" . $extension_in_contact . "\"/>\n";
}

if ($sip_contact_user)
{
	$gateway_config .= "\t\t<param name=\"sip-contact-user\" value=\"" . $sip_contact_user . "\"/>\n";
}

$gateway_config .= "\t\t<param name=\"username\" value=\"" . $username . "\"/>\n";
$gateway_config .= "\t\t<param name=\"password\" value=\"" . $password . "\"/>\n";

if ($park_reason)
{
	$gateway_config .= "\t\t<variables>\n\t\t\t<variable name=\"park_reason\" value=\"" . $park_reason . "\"/>\n\t\t</variables>\n";
}

$gateway_config .= "\t</gateway>\n</include>";

my $new_gateway_file_name = $config_path . '/sip_profiles/external/' . $gateway_name . '.xml';

my $fh;

open($fh,'>',$new_gateway_file_name);
if ( ! $fh ) {
	return -1;
}

print $fh $gateway_config;
close($fh);

system("chown freeswitch:freeswitch ".$new_gateway_file_name);