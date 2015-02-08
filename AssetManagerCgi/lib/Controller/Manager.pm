#!/usr/bin/perl -T

=head1 NAME

Controller::Manager

=head1 SYNOPSIS

my $manager = Controller::Manager->new();

=head1 DESCRIPTION

provides actions for manager.cgi

To facilitate testing of the module, the schemas of tables are not hardcoded but decided upon whether the method is called within the test context or not

=cut

package Controller::Manager;

use strict;
use warnings;
use v5.018;

use utf8;
use open ':encoding(utf8)';

use Model::DB;
use Controller::Helper;

use base qw( Class::Accessor );
__PACKAGE__->mk_ro_accessors( qw(schema) );

#$ENV{DBIC_TRACE} = 1;

=head1 Public methods

=over 4

=item new

=item search

=item upload

=item associate

=item add_software

=back

=cut


=head2 new method

=cut

sub new {
    my $proto = shift or die "I need a class";
    my $class = ref $proto ? ref $proto : $proto;

    my $self  = {};

    my $db = Model::DB->instance();
    $self->{ schema } = $db->schema;

    bless $self, $class;

}

=head2 search method

parameters: 
        name (string) that will be used to find assets with this string in their names 
        test (either not supplied, empty,string or 0/1)

returns:
        array of two arrayrefs:
                                of asset objects
                                of software objects

=cut

sub search {
    my $self = shift;
    my $name = shift;
    my $test = shift;

    $name = sanitize($name);    

    my ( $asset_table, $software_table );
    if ( $test ) {
        $asset_table = 'AssetTest';
        $software_table   = 'SoftwareTest';
    } else {
        $asset_table = 'Asset';
        $software_table   = 'Software';
    }

    my ( $assets_rs, $softwares_rs );
    $assets_rs = $self->schema
                         ->resultset( $asset_table )
                         ->search(
                                     { 'me.name' => { 'like', "%$name%" } },
                                     { prefetch => 'datacentre',
                                       order_by => [ qw/ me.name / ] }
                                 );
    $softwares_rs   = $self->schema
                         ->resultset( $software_table )
                         ->search(
                                     {},
                                     { order_by => [qw/ name /] }
                                 );

    return ( $assets_rs, $softwares_rs );
}

=head2 upload method

parameters: 
        cgi object 
        test (either not supplied, empty,string or 0/1)

new assets are inserted into the database, based on the contents of the uploaded CSV file

=cut

sub upload {
    my $self = shift;
    my $cgi  = shift;
    my $test = shift;

    my $filename = $cgi->param('file');
    unless ( $filename ) {
        if ( not $test && $filename !~ /^([a-zA-Z0-9_.]+)$/ ) {
            $self->{ error } = 'Provided filename was either empty or contained suspicious characters.';
            return;
        }
    }

    my $type = $cgi->uploadInfo($filename)->{'Content-Type'};

    #print Data::Dumper::Dumper($cgi);

    unless ($type eq 'text/csv') {
        $self->{ error } = 'Provided file is not CSV file.';
        return;
    }

    my $tmpfilename = $cgi->tmpFileName($filename);
    unless ( -s $tmpfilename ) {
        $self->{ error } = 'Provided file is empty.';
        return;
    }

    open my $tmp_fh, "<", $tmpfilename;

    ## aggregate assets and datacentres into 2 arrays
    my ( $asset_array_ref, $datacentre_array_ref ) = aggregate_data( $tmp_fh );

    if ( ! scalar @$asset_array_ref ) {
        $self->{ message } = 'No additions to the catalogue - 
                                  problems with parsing the csv filename';
        return;
    }
    
    ## add to catalogue
    if ( ! add_to_catalogue( $self, 
                             $asset_array_ref, $datacentre_array_ref,
                             $test ) ) {
        $self->{ error }   = 'No additions to the catalogue - 
                                  problems with adding to the database';

    } else {
        $self->{ message } = 'New assets added to the database.';

    }

    return 1;
}

=head2 associate method

parameters: 
        cgi object 
        test (either not supplied, empty,string or 0/1)

replaces existing software associates with new ones

=cut

sub associate {
    my $self = shift;
    my ( $cgi, $test ) = @_;

    my ( $asset_id, @software_ids );

    ## get selected info and sanitize selected_software_ids
    $asset_id = $cgi->param('asset');
       $asset_id =~ s/\D+//g;
       $asset_id =~ /^(\d+)$/;
    $asset_id = $1;    

    my @selected_software_ids = $cgi->param('softwares');
    my @sanitized_software_ids = ();
    foreach my $id ( @selected_software_ids ) {
        $id =~ s/\D+//g;
        $id =~ /^(\d+)$/;
        push @sanitized_software_ids, $1;

    }

    my %message = reassociate_software( $self, 
                                        $asset_id, \@sanitized_software_ids,
                                        $test
                                      );

    if ( exists $message{ message } ) {
        $self->{ message } = $message{ message };
        return 1;


    } elsif ( exists $message{ error } ) {
        $self->{ error } = $message{ error };
        return 0;
    }

}

=head2 add_software method

creates a new software if it does not already exist

parameters: 
        name (string) 
        test (either not supplied, empty,string or 0/1)

=cut

sub add_software {
    my $self   = shift;
    my ( $name, $test ) = @_;

    $name = sanitize($name) if $name;    

    my ( $software_table );
    if ( $test ) {
        $software_table   = 'SoftwareTest';
    } else {
        $software_table   = 'Software';
    }

    if ( ! $name ) {
        $self->{ error } = "The software name was empty.";
        return;
    }

    $self->schema ->resultset($software_table)
                  ->find_or_create( { 'name' => "$name" } ) or do {
                            $self->{ error } = "An error happened when adding an software to the database";
                            return;
                          };
    $self->{ message } = "A new software was added to the database if it did not already exist.";

    return 1;

}

=head2 Private methods

none

=cut

1;

