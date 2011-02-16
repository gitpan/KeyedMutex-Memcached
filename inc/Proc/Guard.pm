#line 1
package Proc::Guard;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.04';
use Carp ();

# functional interface
our @EXPORT = qw/proc_guard/;
use Exporter 'import';
sub proc_guard {
    return Proc::Guard->new(do {
        if (@_==1 && ref($_[0])  && ref($_[0]) eq 'CODE') {
            +{ code => $_[0] }
        } else {
            +{ command => [@_] }
        }
    });
}

# OOish interface
use POSIX;
use Class::Accessor::Lite;
Class::Accessor::Lite->mk_accessors(qw/pid/);

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $self = bless {
        _owner_pid => $$,
        auto_start => 1,
        %args,
    }, $class;

    if ($self->{command} && !ref($self->{command})) {
        $self->{command} = [$self->{command}];
    }
    unless ($self->{command} || $self->{code}) {
        Carp::croak("'command' or 'code' is required.");
    }

    $self->start()
        if $self->{auto_start};

    return $self;
}

sub start {
    my $self = shift;

    my $pid = fork();
    die "fork failed: $!" unless defined $pid;
    if ($pid == 0) { # child
        if ($self->{command}) {
            exec @{$self->{command}};
            die "cannot exec @{$self->{command}}: $!";
        } else {
            $self->{code}->();
            exit(0); # exit after work
        }
    }
    $self->pid($pid);
}

sub stop {
    my ( $self, $sig ) = @_;
    return
        unless defined $self->pid;
    $sig ||= SIGTERM;

    kill $sig, $self->pid;
    1 while waitpid( $self->pid, 0 ) <= 0;

    $self->pid(undef);
}

sub DESTROY {
    my $self = shift;
    $self->stop() if defined $self->pid && $$ == $self->{_owner_pid};
}

1;
__END__

=encoding utf8

#line 194
