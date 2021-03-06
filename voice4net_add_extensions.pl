#!/usr/bin/perl

# To install dependencies:
# 	cpan Getopt::Long

use strict;
use warnings;
use Getopt::Long;

my $config_path;
my $domain;
my $output_filename;
my $park_reason;
my $timeout_destination;
my $extension_name;
my $regex;
my $path_sep = '/';
my $dial_plan_template = &get_dialplan_template;
my $new_ext_count = 0;

if (!$ARGV[0]) {
	die "You must specify a comma-delimited string of extensions as a command line argument to add extensions to the dialplan.\n";
}

my $input = $ARGV[0];

GetOptions(
   'domain=s'               => \$domain,
   'confpath=s'             => \$config_path,
   'output-file=s'          => \$output_filename,
   'park-reason=s'          => \$park_reason,
   'extension-name=s'       => \$extension_name,
   'timeout-destination=s'  => \$timeout_destination
);

if ( ! $domain ) {
  $domain='default';
}

if ( ! $config_path ) {
  $config_path = '/etc/freeswitch';
}

if ( ! $output_filename ) {
  $output_filename = 'voice4net_extensions.xml';
}

if ( ! $park_reason ) {
  $park_reason = 'new_call';
}

if ( ! $extension_name ) {
  $extension_name = 'voice4net_extensions';
}

if ( $timeout_destination ) {
	$dial_plan_template = &get_dialplan_template_with_timeout;
}

unless ( -d $config_path ) {
	die "Configuration path '$config_path' does not exist.\n";
}

my $directory_path = $config_path . $path_sep . 'dialplan';
unless ( -d $directory_path ) {
	die "Directory path '$directory_path' does not exist.\n";
}

## Full directory path includes the domain name
my $full_dir_path = $directory_path . $path_sep . $domain;
unless ( -d $full_dir_path ) {
	die "Full path to directory and domain '$full_dir_path' does not exist. \n";
}

unless ( -w $full_dir_path ) {
	die "This user does not have write access to '$full_dir_path'.\n";
}

my $extensions_file_name = $full_dir_path . $path_sep . $output_filename;

if (index($input,",") != -1) {
	my @extensions=split(/,/,$input);
	if (scalar(@extensions) > 1) {
		$regex='^(' . join("|",@extensions) . ')$';
	}
}

if (!$regex) {
	$regex='^' . $input . '$';
}

if ( -f $extensions_file_name ) {
	warn "$extensions_file_name exists, removing...\n";
	unlink $extensions_file_name;
}

if (&print_header()<0) {
	die "Unable to write to '$extensions_file_name'.\n";
}

if ($regex) {
	&add_extension();
}

&print_footer();

print "\nOperation complete. ";
if ( $new_ext_count == 0 ) {
  print "No extensions added.\n";
  exit(0);
} else {
  printf "%d extension%s added.\n", $new_ext_count, $new_ext_count==1 ? "" : "s";
  print "Be sure to reloadxml.";
}

exit(0);

sub print_header {
	my $fh;
	open($fh,'>',$extensions_file_name);
	if ( ! $fh ) {
		return -1;
	}
	print $fh "<!--\n";
	print $fh "****************************************************************\n";
	print $fh "* This xml configuration file was auto-generated by Voice4Net. *\n";
	print $fh "* Changes to this file may cause incorrect behavior and will   *\n";
	print $fh "* be lost if the configuration is regenerated.                 *\n";
	print $fh "****************************************************************\n";
	print $fh "-->\n";
	print $fh "<include>\n";
	close($fh);
	return 0;
}

sub print_footer {
	my $fh;
	open($fh,'>>',$extensions_file_name);
	if ( ! $fh ) {
		return -1;
	}
	print $fh "</include>\n";
	close($fh);
	return 0;
}

sub add_extension {

	my $new_extension = $dial_plan_template;
	$new_extension =~ s/__REGEX__/$regex/g;
	$new_extension =~ s/__PARK_REASON__/$park_reason/g;
	$new_extension =~ s/__EXT_NAME__/$extension_name/g;

	if ( $timeout_destination ) {
		$new_extension =~ s/__TIMEOUT_DESTINATION__/$timeout_destination/g;
	}

	my $fh;
	open($fh,'>>',$extensions_file_name);
	if ( ! $fh ) {
		return -1;
	}

	print $fh $new_extension;
	close($fh);
	print "Added $extension_name to $extensions_file_name\n";
	$new_ext_count++;
}

sub get_dialplan_template {
    my $templ = <<ENDDIALPLANTEMPLATE;
    <extension name="__EXT_NAME__">
        <condition regex="any">
            <regex field="destination_number" expression="__REGEX__"/>
            <regex field="\${sip_from_user}" expression="__REGEX__"/>
            <condition field="\${direction}" expression="^inbound\$">
                <action application="set" data="park_reason=__PARK_REASON__"/>
                <action application="park"/>
            </condition>
        </condition>
    </extension>
ENDDIALPLANTEMPLATE

    return $templ;
}

sub get_dialplan_template_with_timeout {
    my $templ = <<ENDDIALPLANTEMPLATE;
    <extension name="__EXT_NAME__">
        <condition regex="any">
            <regex field="destination_number" expression="__REGEX__"/>
            <regex field="\${sip_from_user}" expression="__REGEX__"/>
            <condition field="\${direction}" expression="^inbound\$">
                <action application="set" data="park_reason=__PARK_REASON__"/>
                <action application="sched_transfer" data="+3 __TIMEOUT_DESTINATION__"/>
                <action application="park"/>
            </condition>
        </condition>
    </extension>
ENDDIALPLANTEMPLATE

    return $templ;
}