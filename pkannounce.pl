#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;

# Catch CTRL+C 
$SIG{INT} = \&kill;

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Getopt::Long;
use PartKeepr::Announce;

my $VERSION = "0.1";

GetOptions(
    'h|help'    => sub { exec( 'perldoc', '-F', $0 ) },
    'v|version' => sub { say "PartKeepr-Announce $VERSION by Sebastian Muszytowski <sebastian\@muszytowski.net"; exit 0; },
) or exit 1;


my $pkannounce = PartKeepr::Announce->new;
$pkannounce->readconfig();
$pkannounce->init();


sub kill {
    if (defined $pkannounce) {
        $pkannounce->sendlogger("LOG_INFO","Recieved SIG_INT, shutting down services.");
        $pkannounce->terminateplugins();
        $pkannounce->sendlogger("LOG_INFO","Closed log for PartKeepr::Announce");
        $pkannounce->closelog();
        undef $pkannounce
    }
    exit 1;
}

AnyEvent->condvar->wait();

__END__

=head1 NAME

pkannounce - A tool to announce changes in the PartKeepr application.

=head1 SYNOPSIS

B<pkannounce.pl> [--help] [--version]

=head1 DESCRIPTION

pkannounce.pl is an abbreviation for PartKeepr Announce. It is able to publish events to several communication channels, such as IRC, XMPP and Twitter. Therefore it openes a tcp listener to recieve messages. Use the provided B<push.sh> to push messages.

=head1 OPTIONS

=over

=item B<--help>

Shows this manpage.

=item B<--version>

Shows the version of pkannounce.

=back 

=head1 CONFIGURATION

Edit the config.ini provided with this package. Further documentation should not ne
necessary due to some documentation in the config file itself.

=head1 AUTHOR

Copyright (C) 2011 by Sebastian Muszytowski E<lt>sebastian@muszytowski.netE<gt>

