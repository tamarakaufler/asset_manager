package AssetManagerApi2::Controller::Docs;

use v5.018;
use utf8;
use open ':encoding(UTF-8)';

use File::Slurp;
use List::MoreUtils qw(any);
use FindBin qw($Bin);

use Moose;
use namespace::autoclean;

use Data::Dumper;

BEGIN { extends 'Catalyst::Controller::REST'; }

use AssetManagerApi2::Helper::Docs;
my $docs = AssetManagerApi2::Helper::Docs->new();

__PACKAGE__->config(default => 'application/json');

=head1 NAME

AssetManagerApi2::Controller::Docs - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path('/readme') :Args(0) {
    my ( $self, $c ) = @_;

    my $content = read_file("$Bin/../README.md");   
    $c->response->body($content);
}

=head2 docs

=cut

sub docs  :Path('/docs')   :ActionClass('REST'){
    my ($self, $c, @req_params) = @_;

    my $type = shift @req_params;

    if ($type) {
        my $source = $c->model('AssetManagerDB')->schema->source_registrations;
        my @tables = map { $source->{$_}->name } keys %$source;

        my $is_valid = any { $_ eq $type } @tables;
        $is_valid = grep { $type eq $_ } @tables;

        say STDERR "$type is present = $is_valid"; 
    
        if (not $is_valid) {
            $self->status_bad_request(
                                        $c,
                                        message => "<$type> is not a valid entity",
                                   );
            # we need to detach otherwise we continue into docs_GET
            $c->detach();
        }
        $c->stash->{ entity_type } = $type;
    }
    else {
        $self->status_bad_request(
                                    $c,
                                    message => "Usage: http://.../docs/asset or http://.../docs/datacentre or http://.../docs/software or http://.../docs/asset_software",
                               );
        # we need to detach otherwise we continue into docs_GET
        $c->detach();
    }

}

=head2 docs_GET

=cut

sub docs_GET {
    my ($self, $c) = @_;

    my $method = $c->stash->{ entity_type } . '_api_doc';
    my $help = $docs->$method;

    $self->status_ok(
                        $c,
                        entity => { examples => $help },
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
