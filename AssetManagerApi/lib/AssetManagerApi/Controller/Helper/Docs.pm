package AssetManagerApi::Controller::Helper::Docs;

=head2 AssetManagerApi::Controller::Helper::Docs

helper class for Controller Docs

=cut

use v5.018;
use utf8;
use open ':encoding(UTF-8)';

use Moose;
use namespace::autoclean;

# --------------------------------- PUBLIC ACCESSORS ---------------------------------

=head2 Public methods
                       asset_api_doc 
                       datacentre_api_doc 
                       software_api_doc 
                       asset_software_api_doc 
=cut

has asset_api_doc => (
                            is      => 'ro',
                            isa     => 'HashRef',
                            builder  => 'asset_doc',
                        );

has datacentre_api_doc => (
                            is      => 'ro',
                            isa     => 'HashRef',
                            builder  => 'datacentre_doc',
                        );

has software_api_doc   => (
                            is      => 'ro',
                            isa     => 'HashRef',
                            builder  => 'software_doc',
                        );

has asset_software_api_doc => (
                            is      => 'ro',
                            isa     => 'HashRef',
                            builder  => 'asset_software_doc',
                        );


=head3 asset_doc

=cut

sub asset_doc {
    my ($self) = @_;

    my $get_examples =  [
                            "curl -X GET  http://localhost:3010/api/asset/id/3",
                            "curl -X GET  http://localhost:3010/api/asset/software/3",
                            "curl -X GET  http://localhost:3010/api/asset/name/Apache%",
                            "curl -X GET  http://localhost:3010/api/asset/name/Apache%202.2",
                        ];
    my $post_examples = [
                            "curl -X POST -F 'file=\@asset.csv'  http://localhost:3010/api/asset",
                            "curl -X POST -F 'file=\@asset.json' http://localhost:3010/api/asset",
                        ];

    my $help = {
                    "GET requests:"  => $get_examples,
                    "POST requests:" => $post_examples,
               };
}


=head3 datacentre_doc

=cut

sub datacentre_doc {
    my ($self) = @_;

    my $get_examples =  [
                            "curl -X GET  http://localhost:3010/api/datacentre/id/3",
                            "curl -X GET  http://localhost:3010/api/datacentre/name/Shoes",
                        ];
    my $post_examples = [
                            "curl -X POST -F 'file=\@asset.csv'  http://localhost:3010/api/asset",
                            "curl -X POST -F 'file=\@asset.json' http://localhost:3010/api/datacentre",
                        ];

    my $help = {
                    "GET requests:"  => $get_examples,
                    "POST requests:" => $post_examples,
               };
}

=head3 software_doc

=cut

sub software_doc {
    my ($self) = @_;

    my $get_examples =  [
                            "curl -X GET  http://localhost:3010/api/software/id/3",
                            "curl -X GET  http://localhost:3010/api/software/name/Smart%20times",
                        ];
    my $post_examples = [
                        ];

    my $help = {
                    "GET requests:"  => $get_examples,
                    "POST requests:" => $post_examples,
               };

}

=head3 asset_software_doc

=cut

sub asset_software_doc {
    my ($self) = @_;

    my $get_examples =  [
                            "curl -X GET  http://localhost:3010/api/asset/software/3",
                        ];
    my $post_examples = [
                        ];

    my $help = {
                    "GET requests:"  => $get_examples,
                    "POST requests:" => $post_examples,
               };
}

1;
