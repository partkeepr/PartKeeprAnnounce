#!/usr/bin/env perl
package PartKeepr::Announce::Plugins::Identica;

use strict;
use warnings;
use AnyEvent;
use Data::Dumper;
use Net::Twitter;
use Sys::Syslog;

sub new{
    my $modulename = shift;
    my $self = {};
    $self->{instance} = undef;
    $self->{config} = {};
    $self->{_modulename} = $modulename;
    $self->{_debug} = 0;
    bless $self;
    return $self;
}

sub setopts{
    my $self = shift;
    $self->{config} = shift;
    $self->debugmessage('LOG_INFO',"Loaded object configuration");
}

sub enabledebug{
    my ($self,$oid) = @_;
    $self->{_debug} = 1;
    $self->{_oid} = $oid;
}

sub debugmessage{
    my ($self,$level,$message) = @_;
    if ($self->{_debug}) {
        syslog($level,"$self->{_oid} debug message: $message");
    }
}

sub init{
    my ($self) = shift;
    $self->{instance} = Net::Twitter->new(
      traits   => [qw/OAuth API::REST/],
      identica            => 1,
      consumer_key        => $self->{config}->{consumer_key},
      consumer_secret     => $self->{config}->{consumer_secret},
      access_token        => $self->{config}->{access_token},
      access_token_secret => $self->{config}->{access_token_secret},
    ); 
    $self->debugmessage('LOG_INFO',"Init done");
}

sub announce {
    my ($self,$message) = @_;
    $self->{instance}->update($message);
    $self->debugmessage('LOG_INFO',"Announced message");
}

sub disconnect{
    my $self = shift;
    $self->debugmessage('LOG_INFO',"Disconnected");
}



1;
