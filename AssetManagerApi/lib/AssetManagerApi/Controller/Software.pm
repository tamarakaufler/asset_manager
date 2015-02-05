package AssetManagerApi::Controller::Software;

use v5.018;
use utf8;

use Lingua::EN::Inflect     qw(PL);

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST'; }

use AssetManagerApi::Controller::Helper::Api qw(
                                                    associate_software
                                                    throws_error
                                              );

__PACKAGE__->config(default => 'application/json');

=head1 NAME

AssetManagerApi::Controller::Tag - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('in Software index');
}

=head2 associate

associate software with asset

input can come from:
    supplied with -T/-d curl flags

=cut

sub associate  :Path('associate')   :ActionClass('REST') {
    my ($self, $c, @url_params) = @_;
}

sub associate_POST {
    my ($self, $c) = @_;

    my $response_data = associate_software($c);
    throws_error($self, $c, $response_data);

    $self->status_created(
                        $c,
                        location => $response_data->{ location },
                        entity   => { AssociatedSoftware => $c->req->data},
                    );
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
