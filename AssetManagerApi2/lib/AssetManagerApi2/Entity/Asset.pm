package AssetManagerApi2::Entity::Asset;

use Moose;
use namespace::autoclean;

use v5.018;
use utf8;
use open    ':encoding(UTF-8)';
use feature 'unicode_strings';

use AssetManagerApi2::Helper::Entity qw(
                                        create_output_structure
                                     );

my ($asset_model,
    $asset_software_model,
    $datacentre_model) = ('AssetManagerDB::Asset',
                          'AssetManagerDB::AssetSoftware',
                          'AssetManagerDB::Datacentre',
                        );

has 'c'          => (is       => 'ro', 
                     isa      => 'AssetManagerApi2',
                     required =>  1,
                    );

has 'dbic'       => (is       => 'ro', 
                     isa      => 'AssetManagerApi2::Schema::AssetManagerDB::Result::Asset',
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
                     writer => '_set_name',
                     );

has 'datacentre' => (is  => 'rw', 
                     isa => 'HashRef',
                     lazy     =>  1,
                     builder => '_build_datacentre',
                     writer => '_set_datacentre',
                    );

has 'software'   => (is  => 'ro', 
                     isa => "ArrayRef[HashRef]|ArrayRef",
                     lazy     =>  1,
                     builder => '_build_software',
                     writer => '_set_software',
                    );

=head2 MOOSE METHODS

=cut

=head3 BUILDARGS

The instance is associated with the DBIC object.
    1) Retrieve the DBIC object
    2) Set up some of the Asset object properties before
       Moose constructer takes over

=cut

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $c    = $_[0]->{c};
    my $dbic = $c->model($asset_model)->find({id => $_[0]->{id}});

    my %props = (
                    c           => $c,
                    id          => $_[0]->{id},
                    type        => 'asset',
                    dbic        => $dbic,
                );

    return $class->$orig(%props);
};
                     
sub _build_type { 
    my ($self) = @_;

    $self->type('asset'); 
}

sub _build_dbic {
    my ($self) = @_;

    my $c    = $_[0]->{c};
    my $dbic = $c->model($asset_model)->find({ id => (ref $_) ? $_[0]->{id} : $_{id} });

    $self->dbic($dbic);
}
 
sub _build_name {
    my ($self) = @_;

    $self->name($self->dbic->name);
}
 
sub _build_datacentre {
    my ($self) = @_;

    my $c = $self->c;
    my $datacentre_dbic = $self->dbic->datacentre;
    my $datacentre = create_output_structure($c, $datacentre_dbic, 'datacentre');

    $self->datacentre($datacentre);
}
 
sub _build_software {
    my ($self) = @_;

    my $c = $self->c;

    my $self_software_dbic = $c->model($asset_model)->find({id => $_[0]->{id}})->softwares;

    my @software = ();
    while (my $package = $self_software_dbic->next) {
        my $software = create_output_structure($c, $package, 'software');
        push @software, $software;
    }

    return \@software;
}

=head2 PRIVATE HELPER METHODS

=cut

=head2 PUBLIC API METHODS

=cut

sub associate_software {
    my ($self, $props) = @_;

    my $c = $self->c;
    my $dbic = $c->model($asset_model)->find_or_create($props);

    create_output_structure($c, $dbic, 'asset_software');
}

__PACKAGE__->meta->make_immutable;

1;
