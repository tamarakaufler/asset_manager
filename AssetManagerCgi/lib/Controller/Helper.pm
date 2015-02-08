#!/usr/bin/perl -T

=head1 NAME

Controller::Helper

=head1 SYNOPSIS

use Controller::Helper;
$name = sanitize($name);

=head1 DESCRIPTION

provides helper methods

=over 4

=item sanitize

=item aggregate_data

=item add_to_catalogue

=back

To facilitate testing of the module, the schemas of tables are not hardcoded but decided upon whether the method is called within the test context or not

=cut

package Controller::Helper;

use strict;
use warnings;
use v5.018;

use utf8;
use open ':encoding(utf8)';

use Text::CSV::Encoded;
use Encode qw(encode);

use base qw(Exporter);

our @EXPORT = qw(   sanitize
                    aggregate_data 
                    add_to_catalogue 
                    reassociate_software
                    massage4output );

=head2 Public methods

=head3 sanitize

    untaints provided string

=cut

sub sanitize {
    my $text = shift;

    return '' if ! $text;    

    ## TODO: this needs to be done by allowing a range of characters rather than by removing unwanted ones
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    $text =~ s#[\\/<>`|!\$*()~{}'"?]+##g;        # ! $ ^ * ( ) ~ [ ] \ | { } ' " ; < > ?
    $text =~ s/\s{2,}/ /g;

    return $text;
}

=head3 aggregate_data

    parameters:   filehandle of the uploaded file
    returns:         array of two arrayrefs: asset names
                                          datacentre names


=cut

sub aggregate_data {
    my ( $fh ) = shift;
    my ( @assets, @datacentres );

    my $csv = Text::CSV::Encoded->new();
    $csv->encoding( 'utf8' );

    while ( my $row = $csv->getline( $fh ) ) {

        ## allow only valid values to be stored, alternatively sanitize
        if ( ( $row->[0] && $row->[0] =~ /[a-zA-Z0-9_\-]+/ && $row->[0] !~ /^\s*name/ ) &&
             ( $row->[1] && $row->[1] =~ /[a-zA-Z0-9_\-]+/ && $row->[1] !~ /^\s*datacentre/ )    ) {
            $row->[0] =~ s/^\s+//; $row->[1] =~ s/^\s+//;
            $row->[0] =~ s/\s+$//; $row->[1] =~ s/\s+$//;
            push @assets,  $row->[0];
            push @datacentres, $row->[1];

        } else {
            ## log error
        }
    }

    return ( \@assets, \@datacentres );

}

=head3 add_to_catalogue

    adds categorized assets to the database

    parameters:   manager object
                  arrayref of asset names
                  arrayref of datacentre names


=cut

sub add_to_catalogue {
    my ( $manager, 
         $assets_ref, $datacentres_ref, 
         $test ) = @_;

    my ( $asset_table, $datacentre_table );
    if ( $test ) {
        $asset_table = 'AssetTest';
        $datacentre_table = 'DatacentreTest';
    } else {
        $asset_table = 'Asset';
        $datacentre_table = 'Datacentre';
    }

    ## Whether or not to use a transaction depends on the business logic (also affects 
    ## the database design
    $manager->schema->txn_do( sub {
        ## add datacentre if does not exist
        ## add the asset
        my $i = 0;
        foreach my $cat_name ( @$datacentres_ref ) {
            my $datacentre = $manager->schema->resultset($datacentre_table)->find_or_create(
                                                                {   name => $cat_name  });
            my $asset = $manager->schema->resultset($asset_table)->create(
                                                                { 
                                                                    name     => $assets_ref->[$i],
                                                                    datacentre => $datacentre->id,
                                                                });
            $i++;
        }
            
    } );

    return if $@;
    return 1;

}

=head2 reassociate_software

    reassociates the specified item of asset:
                  replaces by new association or removes all associations

    parameters:   manager object
                  asset id
                  arrayref of software ids

=cut

sub reassociate_software {

    my ( $manager, 
         $asset_id, $software_ids_ref, 
         $test ) = @_;

    my %message = ();

    ## check the input parameters
    do {
        $message{ error } = 'Internal error - not enough parameters passed into reassociate_software subroutine';
        return %message; 
    } if scalar @_ < 3; 

    do {
        $message{ error } = 'Internal error - Invalid asset id';
        return %message; 
    } if ! $asset_id; 

    ## set up the correct access to tables based on whether we are testing or not
    my ( $asset_table, $software_table );
    if ( $test ) {
        $asset_table = 'AssetTest';
        $software_table   = 'SoftwareTest';
    } else {
        $asset_table = 'Asset';
        $software_table   = 'Software';
    }

    ## get the asset object
    my $asset = $manager->schema->resultset($asset_table)->find( $asset_id ) or do {
        $message{ error } = 
                "An error happened when recovering the asset (id $asset_id) from the database";
        return %message;
    };
    
    ## reassociate
    if ( scalar @{ $software_ids_ref } ) {
        my @selected_softwares = $manager->schema
                                    ->resultset($software_table)
                                    ->search({ id => 
                                                    { '-in' => $software_ids_ref } } ) 
                             or do {
                                        $message{ error } = 
                                        "An error happened when recovering selected softwares from the database";
                                        return %message;
                                   };
        !$asset->set_softwares( \@selected_softwares )
                             or do {
                                        $message{ error } = 
                                        "An error happened when adding associates to the database";
                                        return %message;
                                   };

    } else {
        map { 
                $asset->remove_from_softwares($_) or do {
                                    $message{ error } = "An error happened when adding associates to the database";
                                    return %message;
                               }; 
            } $asset->softwares;

    }

    $message{ message } = 'Software has been reassociated for "' . encode('utf8', $asset->name) . '"';

    return %message;    

}

=head2 massage4output

    massage DBIC data into a Perl structure
    The reason is to encode entity name's Perl internal encoding from iso-8859-1 into utf8 (not sure why this is needed)
    (to avoid wide-character warning and showing the special replacement character on the web page and in the terminal)

=cut

sub massage4output {
    my ($assets_rs, $softwares_rs) = @_;

    my $assets = [];
    my $softwares   = [];

    while (my $asset = $assets_rs->next) {
        say STDERR $asset->name;
        my $datacentre = $asset->datacentre;
        
        push @$assets, { id => $asset->id, name => encode('utf8', $asset->name),  
                            datacentre => { 
                                            id   => $asset->datacentre->id, 
                                            name => encode('utf8', $asset->datacentre->name), 
                                        },
                          };
    }
    while (my $software = $softwares_rs->next) {
        push @$softwares, { id => $software->id, name => encode('utf8', $software->name), };
    }

    return ($assets, $softwares);
}

1;
