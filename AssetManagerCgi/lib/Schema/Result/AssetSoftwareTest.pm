use utf8;
package Schema::Result::AssetSoftwareTest;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::AssetSoftwareTest

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

=head1 TABLE: C<asset_software>

=cut

__PACKAGE__->table("asset_software");

=head1 ACCESSORS

=head2 asset

  data_type: 'integer'
  is_nullable: 0

=head2 software

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "asset",
  { data_type => "integer", is_nullable => 0 },
  "software",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</asset>

=item * L</software>

=back

=cut

__PACKAGE__->set_primary_key("asset", "software");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-02-08 16:59:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2ScoLrGAn3E9CGJ04QBsXw

__PACKAGE__->belongs_to(
  "clothing",
  "Schema::Result::AssetTest",
  { id => "clothing" },
  { is_deferrable => 1, on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "outfit",
  "Schema::Result::SoftwareTest",
  { id => "outfit" },
  { is_deferrable => 1, on_update => "CASCADE" },
);


1;
