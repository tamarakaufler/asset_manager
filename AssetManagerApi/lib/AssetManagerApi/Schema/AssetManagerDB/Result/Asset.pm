use utf8;
package AssetManagerApi::Schema::AssetManagerDB::Result::Asset;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AssetManagerApi::Schema::AssetManagerDB::Result::Asset

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

Related object: L<AssetManagerApi::Schema::AssetManagerDB::Result::Datacentre>

=cut

__PACKAGE__->belongs_to(
  "datacentre",
  "AssetManagerApi::Schema::AssetManagerDB::Result::Datacentre",
  { id => "datacentre" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2015-02-05 19:05:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Btl3l/FsiIwvhMf+d4qITg


__PACKAGE__->has_many(asset_softwares => 'AssetManagerApi::Schema::AssetManagerDB::Result::AssetSoftware',
                                          'asset');
__PACKAGE__->many_to_many(softwares => 'asset_softwares', 'software');

=head3 get_summary

convenience method to access all instance related information

IN:     Asset object
        Catalyst object
OUT:    information massaged into a structure suitable for API output

=cut

sub get_summary {
    my ($self, $c) = @_;

    my @softwares = $self->softwares();
    my $datacentre = $self->datacentre;

    my $self_output = { properties => { id   => $self->id,
                        		name => $self->name, },
                       	link => $c->uri_for("/api/asset/id/" . $self->id)->as_string,
                        docs => $c->uri_for("/docs/asset")->as_string };

    $self_output->{ datacentre } = { properties => { id   => $datacentre->id, 
                                     		     name => $datacentre->name, },
                                     link => $c->uri_for("/api/datacentre/id/" . $datacentre->id)->as_string,
                                     docs => $c->uri_for("/docs/datacentre")->as_string };

    my @software_output = (); 
    for my $software (@softwares) {
        push @software_output, { properties => { id   => $software->id,
                                		 name => $software->name, },
                                 link => $c->uri_for("/api/software/id/" . $software->id)->as_string,
                                 docs => $c->uri_for("/docs/software")->as_string };
    }
    $self_output->{ software } = \@software_output;

    return $self_output;
}

__PACKAGE__->meta->make_immutable;
1;
