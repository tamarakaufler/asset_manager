use utf8;
package Schema::Result::DatacentreTest;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::DatacentreTest

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<datacentre>

=cut

__PACKAGE__->table("datacentre");

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

=head1 RELATIONS

=head2 assets

Type: has_many

Related object: L<Schema::Result::AssetTest>

=cut

__PACKAGE__->has_many(
  "assets",
  "Schema::Result::AssetTest",
  { "foreign.datacentre" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-02-08 16:59:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2wGTniMp/e9bat7fI+Dlxg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
