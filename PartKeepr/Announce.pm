#!/usr/bin/env perl
# PartKeepr::Announce by Sebastian Muszytowski <code at muszytowski dot net>
# License: not yet decided - ask me!
package PartKeepr::Announce;

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Class::Load ':all';
use Config::Tiny;
use Data::Dumper;
use Sys::Syslog;

sub new {
    my $self = {};
    $self->{config}   = undef;
    $self->{services} = {};
    bless $self;
    return $self;
}

sub readconfig {
    my ($self) = shift;
    $self->{config} = Config::Tiny->read('config.ini');
}

sub dumpconfig {
    my $self = shift;
    print Dumper $self->{config};
}

sub init {
    my $self = shift;
    $self->openlogger();
    $self->initplugins();
    $self->createlistener();
}

sub initplugins {
    my $self         = shift;
    my $debugmodules = 0;
    if ( ($self->{config}->{_}->{syslog_modules} eq "true") and ($self->{_logging}) ){
        $debugmodules = 1;
    }
    while (my ($name, $section) = each(%{ $self->{config} })) {
        if (($name ne "_") and ($section->{enabled} eq "true")) {
            my ($mname, $mnumber) = split(/\_/, $name);
            my $classname = "PartKeepr::Announce::Plugins::$mname";
            $self->classloader($classname);
            my $oid = "$mname" . "$mnumber";
            $self->{services}->{$oid} = $classname->new;
            if ($debugmodules) {
                $self->{services}->{$oid}->enabledebug($oid);
            }
            $self->{services}->{$oid}->setopts($section);
            $self->sendlogger('LOG_INFO',"Created new $classname object with ID \"$oid\"");
        }
    }
    if (!%{ $self->{services} }) {
        $self->sendlogger('LOG_ERR', "No service enabled. Shutting down.");
        $self->closelogger();
        exit 1;
    }
    while (my ($oid, $object) = each(%{ $self->{services} })) {
        $object->init();
    }
}

sub terminateplugins {
    my $self = shift;
    $self->sendlogger('LOG_INFO', "Disconnecting all plugins");
    while (my ($oid, $object) = each(%{ $self->{services} })) {
        $object->disconnect();
        $self->sendlogger('LOG_INFO', "Object with ID $oid disconnected.");
    }
}

sub classloader {
    my ($self, $classname) = @_;
    load_class($classname);
    $self->sendlogger('LOG_INFO', "Loaded class $classname");
}

sub announce {
    my ($self, $handle, $message) = @_;
    $self->sendlogger('LOG_INFO', "Announcing new message: $message");
    while (my ($oid, $object) = each(%{ $self->{services} })) {
        $object->announce($message);
    }
}

sub createlistener {
    my $self = shift;
    tcp_server(
        $self->{config}->{_}->{listen},
        $self->{config}->{_}->{port},
        sub {
            my ($fh, $host, $port) = @_;
            if (not $fh) {
                $self->sendlogger('LOG_CRIT', "Server failure: $!");
                return;
            }

            my $handle;
            $handle = AnyEvent::Handle->new(
                fh       => $fh,
                on_eof   => sub { undef $handle },
                on_error => sub { undef $handle },
            );

            $handle->push_read(line => sub { $self->announce(@_); });
        }
    );
}

sub openlogger {
    my $self = shift;
    # ToDo:
    # shorten config into my $cfg = $self->{config}->{_}
    if ($self->{config}->{_}->{syslog} eq "true") {
        openlog(
            "PartKeepr::Announce",
            $self->{config}->{_}->{syslog_opts},
            $self->{config}->{_}->{syslog_facility}
        );
        $self->{_logging} = 1;
        $self->sendlogger('LOG_INFO', "Opened log for PartKeepr::Announce");
    }
    else {
        $self->{_logging} = 0;
    }
}

sub sendlogger {
    my ($self, $level, $message) = @_;
    if ($self->{_logging}) {
        syslog($level, $message);
    }
}

sub closelogger {
    my $self = shift;
    if ($self->{_logging}) {
        closelog();
    }
}

1;
