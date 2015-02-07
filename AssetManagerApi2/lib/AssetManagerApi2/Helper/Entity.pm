package AssetManagerApi2::Helper::Entity;

use strict;
use warnings;
use v5.018;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                    get_entity_type_from_input
                    massage4output
                    create_output_structure
                 );

use Lingua::EN::Inflect         qw(PL);
use Lingua::EN::Inflect::Number qw(to_S);
use Data::Dumper qw(Dumper);

sub _type2table;
 
=head2 PUBLIC API METHODS

    get_entity_type_from_input
    create_output_structure
    massage4output

=head3 get_entity_type_from_input

=cut

sub get_entity_type_from_input {
    my ($field) = @_;

    $field //= 'entity';

    if (@_ == 1) {
        if (!ref $_[0]) {
            $type = $_[0];
        } elsif (ref $_[0] eq 'ARRAY') {
            $type = $_->[1];
        } else {
            $type = $_[0]->{$field};
        }
    }
    elsif ( @_ > 1) {
        $type = $_[1];
    }

    $type ||= 'unknown';

    return $type;
}

=head3 create_output_structure

=cut

sub create_output_structure {
    my ($c, $dbic, $type) = @_;

    my %props;
    if ($type eq 'asset_software') {
        %props = (asset => $dbic->asset, software => $dbic->software);
    }
    else {
        %props = (id => $dbic->id, name => $dbic->name);
    }

    my $entity_props = { %props,
                         link => $c->uri_for("/api/$type/id/" . $dbic->id)->as_string,
                         docs => $c->uri_for("/api/docs/$type")->as_string,
                       };
}

=head3 massage4output

IN:     entity object
OUT:    Perl structure for JSON output

=cut

sub massage4output {
    my ($entity) = @_;

    my $c    = $entity->c;
    my $type = $entity->type;
    my $dbic = $entity->dbic;

    my %massaged = ();
    my ($properties, $m2m_rels) = _get_properties($c, $type);

    my $uri = $c->uri_for("/api/$type/id/" . $dbic->id)->as_string;
    $massaged{link} = $uri;

    ## TODO: extract into a separate sub
    for my $prop (@$properties) {
        my $column = $prop->{name};

        if ($prop->{is_rel}) {
            my $source = _type2table( $column );
            my $rel_schema  = $c->model('AssetManagerDB')->source($source);
        
            my @rel_columns = $rel_schema->columns;
            $massaged{properties}{$column} = { map { $_ => $dbic->$column->$_ } @rel_columns };

            $uri = $c->uri_for("/api/$column/id/" . $dbic->$column->id)->as_string;
            $massaged{properties}{$column}{link} = $uri;
        }
        else {
            $massaged{properties}{$column} = $dbic->$column;
        }

    }

    my @m2m_rel_properties = ();

    ## TODO: extract into a separate sub
    for my $rel_name (@$m2m_rels) {
        # meta info
        my $rel_table   = to_S($rel_name);

        # skip for bridging table (for many-2-many relationships)
        next if $rel_table eq $type;

        my $source      = _type2table($rel_table);
        my $rel_schema  = $c->model('AssetManagerDB')->source($source);
        my @rel_columns = $rel_schema->columns;

        # all the associated relationships of this type with this $dbic
        
        my @rels = $dbic->$rel_name; 

        $massaged{properties}{$rel_name} = [];
        for my $rel (@rels) {
            my $m2m_rel_property = { map { $_ => $rel->$_ } @rel_columns };

            my $uri = $c->uri_for("/api/$rel_table/id/" . $rel->id)->as_string;
            $m2m_rel_property->{link} = $uri;
            $m2m_rel_property->{docs} = $c->uri_for("/docs/$rel_table")->as_string;
            push @{$massaged{properties}{$rel_name}}, $m2m_rel_property;
        }
    }

    # Add documentation link for the main entity type
    $massaged{docs} = $c->uri_for("/docs/$type")->as_string;

    return \%massaged;
}
 
=head2 PRIVATE helper METHODS

    _type2table
    _get_properties

=head3 _type2table

derives DBIx Source from  the table

=cut

sub _type2table {
    my ($type) = @_;

    return ucfirst $type unless $type =~ /_/;

    $type = join '', map { ucfirst $_ } split /_/, $type ;
}


sub _get_properties {
    my ($c, $type) = @_;

    my $source = _type2table( $type );
    my $table_schema  = $c->model('AssetManagerDB')->source($source);
    
    my @columns = map { { name => $_, is_rel => $table_schema->has_relationship($_) } } $table_schema->columns;

    my @m2m_rels    = map { (split /_/, $_)[1] } $table_schema->relationships;
    @m2m_rels = (@m2m_rels) ? @m2m_rels : ();

    return (\@columns, \@m2m_rels);
}

1;
