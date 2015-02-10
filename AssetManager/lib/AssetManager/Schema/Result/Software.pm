use utf8;
package AssetManager::Schema::Result::Software;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AssetManager::Schema::Result::Software

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

=head1 TABLE: C<software>

=cut

__PACKAGE__->table("software");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name_uniq>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name_uniq", ["name"]);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-02-09 21:32:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7/Cg7A4OsdROJhuB3XgdAA

__PACKAGE__->has_many(asset_softwares => 'AssetManager::Schema::Result::AssetSoftware',
                                         'software');
__PACKAGE__->many_to_many(assets => 'asset_softwares', 'asset');

__PACKAGE__->meta->make_immutable;
1;
