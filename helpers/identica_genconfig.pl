#!/usr/bin/env perl
# vim:ts=4:sw=4:expandtab
use strict;
use warnings;
use v5.10;
use Net::Twitter;

my $consumer_key = '5aec8e360a434035d437015863f733e7';
my $consumer_secret = '1b585a5192e50669be4bbd97605ea63b';

my $nt = Net::Twitter->new(
  traits          => ['API::REST', 'OAuth'],
  identica        => 1,
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
