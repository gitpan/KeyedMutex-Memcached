#line 1
package Test::Skip::UnlessExistsExecutable;
use strict;
use warnings;
our $VERSION = '0.041';
use base 'Test::Builder::Module';
use 5.008000;
use File::Spec;
use File::Which qw(which);

use constant WIN32 => $^O eq 'MSWin32';
my $quote = WIN32 ? q/"/ : q/'/;

sub import {
    my $class  = shift;
    my $caller = caller(0);

    # export methods
    {
        no strict 'refs';
        *{"$caller\::skip_all_unless_exists"} = \&skip_all_unless_exists;

    }

    for my $executable (@_) {
        skip_all_unless_exists($executable);
    }
}

sub skip_all_unless_exists {
    my $executable = shift;
    my $found      = can_execute($executable);

    unless ($found) {
        my $skip_all = sub {
            my $builder = __PACKAGE__->builder;

            if ( not defined $builder->has_plan ) {
                $builder->skip_all(@_);
            }
            elsif ( $builder->has_plan eq 'no_plan' ) {
                $builder->skip(@_);
                if ( $builder->can('parent') && $builder->parent ) {
                    die bless {} => 'Test::Builder::Exception';
                }
                exit 0;
            }
            else {
                for ( 1 .. $builder->has_plan ) {
                    $builder->skip(@_);
                }
                if ( $builder->can('parent') && $builder->parent ) {
                    die bless {} => 'Test::Builder::Exception';
                }
                exit 0;
            }
        };

        $skip_all->("The test requires '$executable' in PATH");
    }
}

sub can_execute {
    my $path = shift;

    if ( is_file_path($path) ) {
        return can_execute_path($path);

    }
    else {
        return which($path);
    }
}

sub can_execute_path {
    my $path = shift;
    if ( -x $path ) {
        if ( $path =~ /\s/ && $path !~ /^$quote/ ) {
            $path = "$quote$path$quote";
        }
        return $path;
    }
    else {
        return;
    }
}

sub is_file_path {
    my $path = shift;

    # hmm
    my $dsep = "\/";
    return 1 if $path =~ /$dsep/;
}

1;

__END__

=encoding utf-8

#line 156
