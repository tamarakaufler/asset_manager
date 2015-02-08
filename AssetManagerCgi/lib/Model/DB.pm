#!/usr/bin/perl

=head1 NAME

Model::DB

=head1 SYNOPSIS

my $db_obj = Model::DB->instance();

my $rs = $db_obj->schema->resultset(....);

=head1 DESCRIPTION

provides connection to the database

=cut

package Model::DB;

use strict;
use warnings;

use Schema;

use base qw( Class::Accessor Class::Singleton );
__PACKAGE__->mk_ro_accessors( qw(schema) );

=head2 new method

=cut

sub _new_instance {
	my $proto = shift;
	my $class = ref $proto ? ref $proto : $proto;
	
	my $self  = {};

	## TODO: the database connection info would normally be elsewhere
	$self->{ schema } = Schema->connect("dbi:mysql:assetmanager", 
					                    'assetmanager', 'StRaW101',
        				                { mysql_enable_utf8 => 1 },
					    ) or die "Cannot connect to database";

	bless $self, $class;

}

1;
