#!/usr/bin/env perl
package PartKeepr::Announce::Plugins::IRC;

use strict;
use warnings;
use AnyEvent;
use AnyEvent::IRC::Util qw/split_prefix prefix_nick/;
use AnyEvent::IRC::Client;
use Data::Dumper;
use Sys::Syslog;

sub new{
    my $modulename = shift;
    my $self = {};
    $self->{instance} = AnyEvent::IRC::Client->new();
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
    $self->register_callbacks();
    $self->connect();
    $self->sendcmd();
    $self->debugmessage('LOG_INFO',"Init done");
}

sub announce {
    my ($self,$message) = @_;
    my $channel = $self->{config}->{channel};
    $self->{instance}->send_chan($channel, 'PRIVMSG', $channel, $message);
    $self->debugmessage('LOG_INFO',"Announced message");
}

sub connect {
    my $self = shift;
    $self->{instance}->send_srv('JOIN', $self->{config}->{channel});
    if ( $self->{config}->{ssl} eq "true" ) {
        $self->{instance}->enable_ssl();
    }
    $self->{instance}->connect($self->{config}->{host}, $self->{config}->{port}, {
        nick => $self->{config}->{nick},
        user => $self->{config}->{user},
        real => 'PartKeepr::Announce::Plugins::IRC',
    });
}

sub reconnect {
    my $self = shift;
    my $timer;
    $timer = AnyEvent->timer(
        after => 10,
        cb => sub { 
            undef $timer; 
            $self->connect();
        }
    );
}

sub disconnect {
    my $self = shift;
    $self->{instance}->disconnect();
    $self->debugmessage('LOG_INFO',"Disconnected Service");
}

sub register_callbacks {
    my $self = shift;
    $self->{instance}->reg_cb(
        connect => sub {
            my ($instance, $err) = @_;
            if ($err) {
                $self->reconnect();
                $self->debugmessage('LOG_INFO',"Reconnecting due to error: $err");
            }
        },
        publicmsg => sub {
            my ($instance,$mychannel,$ircmsg) = @_;
            print Dumper $self;
        },
        privatemsg => sub {
            my ($instance,$mynick,$ircmsg) = @_;
            my $foo = prefix_nick($ircmsg->{prefix});
            print Dumper $foo;
        }
    );
    $self->{instance}->ctcp_auto_reply ('VERSION', ['VERSION', 'PartKeepr::Announce::Plugins::IRC by Sebastian Muszytowski']);
    $self->debugmessage('LOG_INFO',"Registered Callbacks");
}

sub sendcmd {
    my $self = shift;
    if ($self->{config}->{sendcmd} eq "true") {
        $self->{instance}->send_srv(PRIVMSG => $self->{config}->{sendcmd_to}, $self->{config}->{sendcmd_cmd});
    }
}

1;
