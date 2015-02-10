package AssetManager::Controller::Helper;

=head1 AssetManager::Controller::Helper

provides helper methods

=cut

use strict;
use warnings;
use v5.018;
use utf8;
use open ':encoding(utf8)';
use feature 'unicode_strings';
use Encode qw(encode);

use Text::CSV::Encoded;

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
    $text =~ s#[\\/<>`|!\$*()~{}'"?]+##g;        # ! $ ^ & * ( ) ~ [ ] \ | { } ' " ; < > ?
    $text =~ s/\s{2,}/ /g;

    return $text;
}

=head3 aggregate_data

    input parameters:   filehandle of the uploaded file
    output parameters:  array of two arrayrefs: asset names
                                                datacentre names


=cut

sub aggregate_data {
    my ( $fh ) = shift;
    my ( @assets, @datacentres );

    my $csv = Text::CSV::Encoded->new ({
        encoding_in  => "utf-8", 
        encoding_out => "utf-8", 
    });

    my $i = 0;
    while ( my $row = $csv->getline( $fh ) ) {

        ## allow only valid values to be stored, alternatively sanitize
        if ( ( $row->[0] && $row->[0] =~ /[a-zA-Z0-9_\- ]+/ && $row->[0] !~ /^\s*name/ ) &&
             ( $row->[1] && $row->[1] =~ /[a-zA-Z0-9_\- ]+/ && $row->[1] !~ /^\s*datacentre/ )    ) {
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

    adds assets to the database

    input parameters:   Catalyst object
                        arrayref of asset names
                        arrayref of datacentre names


=cut

sub add_to_catalogue {
    my ( $c, $assets_ref, $datacentres_ref ) = @_;
        
    ## Whether or not to use a transaction depends on the business logic (also affects 
    ## the database design
    $c->model('DB')->txn_do( sub {
        ## add datacentre if does not exist
        ## add the asset
        my $i = 0;
        foreach my $dat_name ( @$datacentres_ref ) {
            my $datacentre = $c->model('DB::Datacentre')->find_or_create(
                                                                {   name => $dat_name  });
            my $asset = $c->model('DB::Asset')->create(
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

=head3 reassociate_software

    reassociate software with asset:
                  replaces with new association or removes all associations in asset_software

    parameters:   c object
                  asset id
                  arrayref of software ids

=cut

sub reassociate_software {

    my ( $c, 
         $asset_id, $software_ids_ref ) = @_;

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

    ## get the asset object
    my $asset = $c->model('DB::Asset')->find( $asset_id ) or do {
        $message{ error } = 
                "An error happened when retrieving asset (id $asset_id) from the database";
        return %message;
    };
    
    ## reassociate
    if ( scalar @{ $software_ids_ref } ) {
        my @selected_softwares = $c->model('DB::Software')
                                 ->search({ id => { '-in' => $software_ids_ref } } ) 
                             or do {
                                        $message{ error } = 
                                        "An error happened when recovering selected softwares from the database";
                                        return %message;
                                   };
        $asset->update_softwares( $c, $software_ids_ref )
                             or do {
                                        $message{ error } = 
                                        "An error happened when associating software";
                                        return %message;
                                   };

    } else {
                $asset->remove_softwares() or do {
                                    $message{ error } = "An error happened when disassociating software";
                                    return %message;
                               }; 
    }

    $message{ message } = 'The asset item "' . encode('utf8', $asset->name) . '" has been reassociated';

    return %message;    

}

=head3 massage4output

    massage DBIC data into a Perl structure
    The reason is to encode entity name's Perl internal encoding from iso-8859-1 into utf8 (not sure why this is needed)
    (to avoid wide-character warning and showing the special replacement character on the web page and in the terminal)

=cut

sub massage4output {
    my ($assets_rs, $softwares_rs) = @_;

    my $assets = [];
    my $softwares   = [];

    while (my $asset = $assets_rs->next) {
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
