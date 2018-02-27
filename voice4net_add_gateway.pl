#!/usr/bin/perl

#script invocation
#perl /usr/share/freeswitch/scripts/voice4net_add_gateway.pl --gateway-name='testdemo' --proxy='abc.example.com' --register='true' --caller-id-in-from='true' --from-user='fromuser' --from-domain='abc.example.com' --extension='testdemo' --extension-in-contact='true' --sip-contact-user="testdemo" --username='username' --password='password' --confpath='/tmp/'

use strict;
use warnings;
use Getopt::Long;

my $gateway_name;
my $proxy;
my $register;
my $caller_id_in_from;
my $from_user;
my $from_domain;
my $extension;
my $extension_in_contact;
my $sip_contact_user;
my $username;
my $password;
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
   'confpath=s'          		=> \$config_path
);

if ( ! $gateway_name || ! $proxy || ! $from_user || ! $username || ! $password) {
  return -1;
}

if (! $config_path)
{
	$config_path = "/etc/freeswitch/";
}

my $gateway_template = "<include>\n";

$gateway_template .= "\t<gateway name=\"" . $gateway_name . "\">\n";
$gateway_template .= "\t  <param name=\"proxy\" value=\"" . $proxy . "\"/>\n";

if ($register)
{
	$gateway_template .= "\t  <param name=\"register\" value=\"" . $register . "\"/>\n";
}

if ($caller_id_in_from)
{
	$gateway_template .= "\t  <param name=\"caller-id-in-from\" value=\"" . $caller_id_in_from . "\"/>\n";
}

$gateway_template .= "\t  <param name=\"from-user\" value=\"" . $from_user . "\"/>\n";

if ($from_domain)
{
	$gateway_template .= "\t  <param name=\"from-domain\" value=\"" . $from_domain . "\"/>\n";
}

if ($extension)
{
	$gateway_template .= "\t  <param name=\"extension\" value=\"" . $extension . "\"/>\n";
}

if ($extension_in_contact)
{
	$gateway_template .= "\t  <param name=\"extension-in-contact\" value=\"" . $extension_in_contact . "\"/>\n";
}

if ($sip_contact_user)
{
	$gateway_template .= "\t  <param name=\"sip-contact-user\" value=\"" . $sip_contact_user . "\"/>\n";
}

$gateway_template .= "\t  <param name=\"username\" value=\"" . $username . "\"/>\n";
$gateway_template .= "\t  <param name=\"password\" value=\"" . $password . "\"/>\n";

$gateway_template .= "\t</gateway>\n</include>";

my $new_gateway_file_name = $config_path . '/sip_profiles/external/' . $gateway_name . '.xml';

my $fh;

open($fh,'>',$new_gateway_file_name);
if ( ! $fh ) {
	return -1;
}

print $fh $gateway_template;
close($fh);

system("chown freeswitch:freeswitch ".$new_gateway_file_name);