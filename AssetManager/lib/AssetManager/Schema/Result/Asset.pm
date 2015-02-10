use utf8;
package AssetManager::Schema::Result::Asset;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AssetManager::Schema::Result::Asset

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<asset>

=cut

__PACKAGE__->table("asset");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 datacentre

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "datacentre",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name_cat_uniq>

=over 4

=item * L</name>

=item * L</datacentre>

=back

=cut

__PACKAGE__->add_unique_constraint("name_cat_uniq", ["name", "datacentre"]);

=head1 RELATIONS

=head2 datacentre

Type: belongs_to

Related object: L<AssetManager::Schema::Result::Datacentre>

=cut

__PACKAGE__->belongs_to(
  "datacentre",
  "AssetManager::Schema::Result::Datacentre",
  { id => "datacentre" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-02-09 21:32:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bvl+y/GSPuROgur+kDFL2g


__PACKAGE__->has_many( asset_softwares => 'AssetManager::Schema::Result::AssetSoftware',
					  'asset');
__PACKAGE__->many_to_many( softwares => 'asset_softwares', 'software');


sub update_softwares {
    my ($self, $c, $ids) = @_;

	eval {
	    $self->remove_softwares($c);
	
	    for my $id (@$ids) {
	        $c->model('DB::AssetSoftware')->find_or_create( { asset => $self->id, software => $id } );
	    }
	};
	
    if ($@) {
	    return;
    } 
    else {
        return 1;
    }
}

sub remove_softwares {
    my ($self, $c) = @_;

    my $asset_soft_rs = $c->model('DB::AssetSoftware')->search( { asset => $self->id } );
    $asset_soft_rs->delete if $asset_soft_rs;
}

__PACKAGE__->meta->make_immutable;
1;
