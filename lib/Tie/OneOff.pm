# $Id: OneOff.pm,v 1.13 2002/10/14 14:20:53 bam Exp $

package Tie::OneOff;
our $VERSION = 0.1;

=head1 NAME

Tie::OneOff - create tied variables without defining a separate package 

=head1 SYNOPSIS

    require Tie::OneOff;
    
    tie my %REV, 'Tie::OneOff' => {
	FETCH => sub { reverse shift },
    };

    print "$REV{olleH}\n"; # Hello

    sub make_counter {
	my $step = shift;
	my $i = 0;
        tie my $counter, 'Tie::OneOff' => {
	    BASE => \$i, # Implies: STORE => sub { $i = shift }
	    FETCH => sub { $i += $step },
        };
	\$counter;
    }

    my $c1 = make_counter(1);
    my $c2 = make_counter(2);
    $$c2 = 10;
    print "$$c1 $$c2 $$c2 $$c2 $$c1 $$c1\n"; # 1 12 14 16 2 3
 
=head1 DESCRIPTION

The Perl tie mechanism ties a Perl variable to a Perl object.  This
means that, conventionally, for each distinct set of tied variable
semantics one needs to create a new package.  Sometimes it would seem
more natural to associate a dispatch table hash directly with the
variable and pretend as if the intermediate object did not exist.
This is what Tie::OneOff does.

It is important to note that in this model there is no object to hold
the instance data for the tied variable.  The callbacks in the
dispatch table are called not as methods but as simple subroutines.
If there is to be any instance information for a variable tied using
Tie::OneOff it must be in lexical variables that are referenced by the
callback closures.

Tie::OneOff does not itself provide any default callbacks.  This can
make defining a full featured hash interface rather tedious.  To
simplify matters the element BASE in the dispatch table can be used to
specify a "base object" whose methods provide the default callbacks.  If a
reference to an unblessed Perl variable is specified as the BASE then
the variable is blessed into the appropriate Tie::StdXXXX package.  In
this case the unblessed variable used as the base must, of course, be
of the same type as the variable that is being tied.

In make_counter() in the synopsis above, the variable $i gets blessed
into Tie::StdScalar. Since there is no explict STORE in the dispatch
table, an attempt to store into a counter is implemented by calling
(\$i)->STORE(@_) which in turn is resolved as
Tie::StdScalar::STORE(\$i,@_) which in turn is equivalent to $i=shift.

=head1 SEE ALSO

L<perltie>, L<Tie::Scalar>, L<Tie::Hash>, L<Tie::Array>.

=cut

use strict;
use warnings;
use base 'Exporter';
use vars qw ( $AUTOLOAD );

my %not_pass_to_base = (
		DESTROY => 1,
		UNTIE => 1,
		);

sub AUTOLOAD {
    my $self = shift;
    my ($func) = $AUTOLOAD =~ /(\w+)$/ or die;
    # All class methods are the contstuctor
    unless ( ref $self ) {
	unless ($func =~ /^TIE/) {
	    require Carp;
	    +Carp::croak "Non-TIE class method $func called for $self";
	}
	$self = bless ref $_[0] ? shift : { @_ }, $self;
	if ( my $base = $self->{BASE} ) {
	    require Scalar::Util;
	    unless ( Scalar::Util::blessed($base)) {
		my $type = ref $base;
		unless ( "TIE$type" eq $func ) {
		    require Carp;
		    $type ||= 'non-reference';
		    +Carp::croak "BASE cannot be $type in " . __PACKAGE__ . "::$func";
		}
		require "Tie/\u\L$type.pm";
		bless $base, "Tie::Std\u\L$type";
	    }
	} 
	return $self;
    }
    my $code = $self->{$func} or do {
	return if $not_pass_to_base{$func};
	my $base = $self->{BASE};
	return $base->$func(@_) if $base;
	require Carp;
	+Carp::croak "No $func handler defined in " . __PACKAGE__ . " object";
    }; 
    goto &$code;
}

1;
