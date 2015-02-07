package AssetManagerApi2::Controller::Entity;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST'; }
__PACKAGE__->config(default => 'application/json');

use AssetManagerApi2::Entity::Asset;
use AssetManagerApi2::Helper::Entity qw(
                                        massage4output
                                     );

##use AssetManagerApi2::Controller::Helper::Api qw(
##                                    get_asset_summary
##                                    get_listing
##
##                                    process_csv_upload
##                                    process_json_upload
##                                    create_from_inline_input
##
##                                    create_entity
##                                    update_entity
##                                    delete_entity
##
##                                    throws_error
##                                              );

=head1 NAME

AssetManagerApi2::Controller::Entity - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched AssetManagerApi2::Controller::Entity in Entity.');
}

=head2 api

=cut

sub api  :Path('/api')   :ActionClass('REST') {
    my ($self, $c, @url_params) = @_;

    $c->stash->{ entity_type }   = shift @url_params;

    if (! $c->stash->{ entity_type }        || 
        ! scalar grep { $c->stash->{ entity_type } eq $_ } qw(asset datacentre software asset_software)) {
        $self->status_bad_request(
                            $c,
                            message => 'Error: /api/asset|datacentre|software asset_software/...',
                        );
    }

    $c->stash->{ search_params } = \@url_params;
}

=head2 api_GET

=cut

sub api_GET {
    my ( $self, $c ) = @_;

    my $type =  $c->stash->{entity_type};

    my $entity = AssetManagerApi2::Entity::Asset->new({ c => $c, id => 1});
    my $response_data = [massage4output($entity)];

    #my $response_data = [{ id => $entity->id, name => $entity->name, datacentre => $entity->datacentre->name }];
    
    #my $response_data = get_listing($c, $type, $c->stash->{ search_params });
    #throws_error($self, $c, $response_data);

    if (scalar @$response_data) {
        $self->status_ok(
                          $c,
                          entity => $response_data,
                        );
    }
    else {
        my $plural = ucfirst PL($type);
        $self->status_not_found(
                          $c,
                          message => "No $plural found",
                        );
    }

}

=head2 api_POST

creates multiple assets and categories from an uploaded CSV/JSON (array of hashes) file,
will skip existing entities and proceed further

the uploaded file extension is used to determine the type of input data. If curl and other 
clients mandatorily use the content-type header, then $upload->type could be used to tell
the input data format 

=cut

sub api_POST {
    my ($self, $c) = @_;

##    my $response_data = {};
##    my $upload        = $c->request->upload('file');
##
##    ## provided through -F -------------------------------------------------------------------
##    if ($upload) {
##
##        my $filename    = $upload->filename;
##        my $fh          = $upload->fh;
##
##        if (! $upload->size) {
##            $response_data->{ error } = {
##                                            status  => 'status_bad_request',
##                                            message => 'Error: Uploaded file was empty.',
##                                        };
##        }
##        elsif ($upload->size >= 5_000_000) {
##            $response_data->{ error } = {
##                                            status  => 'status_bad_request',
##                                            message => 'Error: Upload size of a file is 5Mb.',
##                                        };
##        }
##        elsif ($c->stash->{entity_type} =~ /\A(asset|datacentre)\z/ && $filename =~ m/\.csv$/) {
##            $response_data = process_csv_upload($c, $upload->tempname);
##        }
##        elsif ($filename =~ /\.json$/) {
##            $response_data = process_json_upload($c, $fh);
##        }
##        else {
##            $response_data->{ error } = {
##                                            status  => 'status_bad_request',
##                                            message => 'Error: Content is not supported.',
##                                        };
##        }
##        throws_error($self, $c, $response_data);
##    }
##    ## provided through -d/-T -------------------------------------------------------------------
##    elsif ($c->req->data) {
##
##        $response_data = create_from_inline_input($c);
##        throws_error($self, $c, $response_data);
##    } 
##
##    # this, for performace reasons, returns links to all created resources in one response
##    # for one created resource the response would be >>  status_created with location => $uri <<
##    $self->status_ok(
##                        $c,
##                        entity => $response_data,
##                    );
}

=head2 api_PUT

TODO

=cut

sub api_PUT {
    my ($self, $c) = @_;

    $c->response->body('So much more to do: updating ... ');
}

=head2 api_DELETE

TODO

=cut

sub api_DELETE {
    my ($self, $c) = @_;

    $c->response->body('So much more to do: deleting ... ');
}


=encoding utf8

=head1 AUTHOR

Tamara Kaufler,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;


=encoding utf8

=head1 AUTHOR

Tamara Kaufler,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
