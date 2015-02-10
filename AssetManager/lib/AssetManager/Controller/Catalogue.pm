package AssetManager::Controller::Catalogue;

use base 'Catalyst::Controller';

use lib qw( .. );
use v5.018;
use utf8;
use open ':encoding(utf8)';
use feature 'unicode_strings';
use Encode qw(encode);

use AssetManager::Controller::Helper;

$ENV{DBIC_TRACE} = 1;

=head1 NAME

AssetManager::Controller::Catalogue - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

=head1 METHODS

=cut

=head2 index

redirects to api method

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->detach('search');
}

=head2 search

=cut

sub search : Path('search') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    my $name = sanitize( $c->req->param('asset_name') );
    my $assets_rs = $c->model('DB::Asset')
                         ->search(
                                     { 'me.name' => { 'like', "%$name%" } },
                                     {  prefetch => 'datacentre',
                                        order_by => [qw/ me.name /] }
                                 );
    my $softwares_rs   = $c->model('DB::Software')
                         ->search(
                                     {},
                                     { order_by => [qw/ name /] }
                                 );
     
    my ($assets, $softwares) = massage4output($assets_rs, $softwares_rs);

    $c->stash->{ assets }    = $assets;
    $c->stash->{ softwares } = $softwares;

    $c->stash->{ mode }      = 'search';
    $c->stash->{ template }  = 'index.tt';

}

=head2 upload

=cut

sub upload :Path('upload') {
    my ( $self, $c ) = @_;

    $c->stash->{ template } = 'index.tt';

    ## show default page if the filename is empty or has bad characters
    
    unless ( $c->req->param('file') && $c->req->param('file') =~ /^([a-zA-Z0-9_.]*)$/ ) {
        $c->stash->{ error } = 'Provided filename was either empty or unclean and could not be processed.';
        $c->detach('/index');
    }

    ## try to upload the file
    my $upload = $c->req->upload('file');
    my $fh     = $upload->fh;

    if ($upload->type eq 'text/csv' ) {

        if ( ! $upload->size ) {
            $c->stash->{ error } = 'The supplied file is empty';
            $c->detach('/index');
        }

        ## aggregate assets and datacentres
        my ( $asset_array_ref, $datacentre_array_ref ) = aggregate_data( $fh );

        if ( ! scalar @$asset_array_ref ) {
            $c->stash->{ error } = 'No additions to the catalogue - 
                                      problems with parsing the csv file';
            $c->detach('/index');
        }

        ## aggregate assets and datacentres into 2 arrays

        if ( ! add_to_catalogue( $c, $asset_array_ref, $datacentre_array_ref) ) {
            $c->stash->{ error } = 'No additions to the catalogue - 
                                      problems with adding items to the catalogue';
        }
        $c->stash->{ message }  = 'New asset added to the database.';

    } else {
        $c->stash->{ error }    = 'Only CSV files can be uploaded';
    }

}


=head2 associate

replaces existing software with new associations

=cut

sub associate :Path('associate') {
    my ( $self, $c ) = @_;

    my ( $asset_id, @software_ids );

    $c->stash->{ template } = 'index.tt';

    ## get selected info and sanitize selected_software_ids
    $asset_id = $c->req->param('asset');
    $asset_id =~ s/\D+//g;
    $asset_id =~ /^(\d+)$/;
    $asset_id = $1;    
    my @selected_software_ids = $c->req->param('softwares');
    my @sanitized_software_ids = ();
    foreach my $id ( @selected_software_ids ) {
        $id =~ s/\D+//g;
        $id =~ /^(\d+)$/;
        push @sanitized_software_ids, $1;
    }

    my %message = reassociate_software( $c, 
                                        $asset_id, \@sanitized_software_ids);

    if ( exists $message{ message } ) {
        $c->stash->{ message } = $message{ message };
        $c->stash->{ asset_softwares }  = $message{ asset_softwares };
        $c->detach('/index');


    } elsif ( exists $message{ error } ) {
        $c->stash->{ error } = $message{ error };
        $c->detach('/index');
    }

}
=head2 add_software

creates a new software if it does not alrready exist

=cut

sub add_software :Path('add_software') {
    my ( $self, $c ) = @_;

    my $name = sanitize( $c->req->param('software_name') );

    $c->model('DB::Software')
      ->find_or_create( { 'name' => "$name" } ) or do {
                        $c->stash->{ error } = "An error happened when adding an software to the database";
                        $c->detach('/index');
                     };

    $c->stash->{ message }  = "A new software was added to the database if it did not already exist.";
    $c->stash->{ template } = 'index.tt';

}


=head2 Private methods

none

=cut


=head1 AUTHOR

Tamara Kaufler,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
