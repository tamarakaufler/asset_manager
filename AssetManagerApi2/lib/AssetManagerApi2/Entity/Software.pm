package AssetManagerApi2::Entity::Software;

use Moose;
use namespace::autoclean;

use v5.018;
use utf8;
use open    ':encoding(UTF-8)';
use feature 'unicode_strings';

use AssetManagerApi2::Helper::Entity qw(
                                        create_output_structure
                                     );

my  $software_model = 'AssetManagerDB::Software';

has 'c'          => (is       => 'ro', 
                     isa      => 'AssetManagerApi2',
                     required =>  1,
                    );

has 'dbic'       => (is       => 'ro', 
                     isa      => 'AssetManagerApi2::Schema::AssetManagerDB::Result::Software',
                     builder  => '_build_dbic',
                    );

has 'type'       => (is       => 'ro', 
                     isa      => 'Str',
                     lazy     =>  1,
                     builder  => '_build_type',
                     );

has 'id'         => (is       => 'ro', 
                     isa      => 'Int',
                     required =>  1,
                    );

has 'name'       => (is  => 'rw', 
                     isa => 'Str',
                     lazy     =>  1,
                     builder => '_build_name',
                     );

has 'assets  '   => (is  => 'ro', 
                     isa => "ArrayRef[HashRef]|ArrayRef",
                     lazy     =>  1,
                     builder => '_build_assets',
                    );

=head2 MOOSE METHODS

=cut

=head3 BUILDARGS

The instance is associated with the DBIC object.
    1) Retrieve the DBIC object
    2) Set up some of the Software object properties before
       Moose constructer takes over

=cut

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $c    = $_[0]->{c};
    my $dbic = $c->model($software_model)->find({id => $_[0]->{id}});

    my %props = (
                    c           => $c,
                    id          => $_[0]->{id},
                    type        => 'software',
                    dbic        => $dbic,
                );

    return $class->$orig(%props);
};
                     
sub _build_type { 
    my ($self) = @_;
}

sub _build_dbic {
    my ($self) = @_;
}
 
sub _build_name {
    my ($self) = @_;

    $self->name($self->dbic->name);
}
 
sub _build_assets {
    my ($self) = @_;

    my $c = $self->c;
    my $self_assets_dbic = $self->dbic->assets;

    my @assets = ();
    while (my $package = $self_assets_dbic->next) {
        my $asset = create_output_structure($c, $package, 'asset');
        push @assets, $asset;
    }

    $self->assets(\@assets);
}

=head2 PRIVATE HELPER METHODS

=cut

=head2 PUBLIC API METHODS

=cut


__PACKAGE__->meta->make_immutable;

1;
