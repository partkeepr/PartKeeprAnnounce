#!/usr/bin/env perl
# vim:ts=4:sw=4:expandtab
use strict;
use warnings;
use v5.10;
use Net::Twitter;

my $consumer_key = 'k5MK8DcgIxvkpq83wgeyHQ';
my $consumer_secret = 'eKpLsC1aDvGTnI2k5H4oHaCSM5u0pqflwZU3c2lDJY';

my $nt = Net::Twitter->new(
  traits          => ['API::REST', 'OAuth'],
  consumer_key    => $consumer_key,
  consumer_secret => $consumer_secret
);

say "Requesting authorization URL ...";
say "";
say " ", $nt->get_authorization_url;
say "";
say "Please visit the Link and enter the PIN";
print "PIN: ";
my $pin = <STDIN>; 
chomp $pin;

my($access_token, $access_token_secret, $user_id, $screen_name) = $nt->request_access_token(verifier => $pin);
say "You can paste the output to the config file:";
say "";
say "";
say "consumer_key=$consumer_key";
say "consumer_secret=$consumer_secret";
say "access_token=$access_token";
say "access_token_secret=$access_token_secret";
say "";
say "";
