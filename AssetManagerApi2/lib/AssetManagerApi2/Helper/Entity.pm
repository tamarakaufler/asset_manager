package AssetManagerApi2::Helper::Entity;

use strict;
use warnings;
use v5.018;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                    create_entity
                    create_entity_input
                    massage4output
                    create_output_structure

                    type2table
                    get_listing

                    process_csv_upload
                    process_json_upload
                    create_from_inline_input

                    error_exists
                    throws_error
                 );

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Lingua::EN::Inflect         qw(PL);
use Lingua::EN::Inflect::Number qw(to_S);
use Scalar::Util                qw(blessed);
use List::MoreUtils             qw(any);
use JSON                        qw(from_json);
use Text::CSV::Auto;
use URI::Escape;

use Data::Dumper qw(Dumper);
$ENV{DBIC_TRACE} = 1;

use AssetManagerApi2::EntityFactory;

=head2 PUBLIC API METHODS

    create_entity_input
    create_output_structure
    massage4output
    get_listing
    type2table

    error_exists
    throws_error

=cut

=head3 type2table

derives DBIx Source from  the table

=cut

sub type2table {
    my ($type) = @_;

    return ucfirst $type unless $type =~ /_/;

    $type = join '', map { ucfirst $_ } split /_/, $type ;
}

=head3 create_entity_input

=cut

sub create_entity_input {
    my ($c, $type, $dbic) = @_;

    my %props;
    if ($type eq 'asset_software') {
        %props = (c => $c, type => $type, asset => $dbic->asset, software => $dbic->software);
    }
    else {
        %props = (c => $c, type => $type, id => $dbic->id, name => $dbic->name);
    }

    return \%props;
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

    my $entity_props = { properties => \%props,
                         link       => $c->uri_for("/api/$type/id/" . $dbic->id)->as_string,
                         docs       => $c->uri_for("/api/docs/$type")->as_string,
                       };
}

=head3 massage4output

IN:     Entity object
OUT:    Perl structure for JSON output

=cut

sub massage4output {
    my ($entity) = @_;

    my $c    = $entity->c;
    my $type = $entity->type;
    my $dbic = $entity->dbic;

    my %massaged = ();
    my ($properties, $simple_rels, $m2m_rels) = _get_properties($c, $type);

    my $uri = $c->uri_for("/api/$type/id/" . $dbic->id)->as_string;
    $massaged{link} = $uri;

    ## TODO: extract into a separate sub
    for my $prop (@$properties) {
        my $column = $prop->{name};

        if ($prop->{is_rel}) {
            my $source = type2table( $column );
            my $rel_schema  = $c->model('AssetManagerDB')->source($source);
        
            my @rel_columns = $rel_schema->columns;
            $massaged{properties}{$column} = { map { $_ => $dbic->$column->$_ } @rel_columns };

            $uri = $c->uri_for("/api/$column/id/" . $dbic->$column->id)->as_string;
            $massaged{properties}{$column}{link} = $uri;

            $uri = $c->uri_for("/docs/$column")->as_string;
            $massaged{properties}{$column}{docs} = $uri;
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

        my $source      = type2table($rel_table);
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

=head3 get_listing

IN:     Catalyst object
        entity type
        search parameters (arrayref)

OUT:    hashref response

=cut

sub get_listing {
    my ($c, $type, $params) = @_;

    my @rows = ();
    my $source = type2table( $type );
    eval {
        my $search_option = _process_search_params($c, $type, $params);

        @rows  = $c->model("AssetManagerDB::$source")
                   ->search( $search_option->{where},
                             $search_option->{join});
    
    };
    if ($@) {
        my $error = { error => { status  => 'status_bad_request', 
                                 message => "Problems with retrieving $source data: " . substr($@, 0, 250 ), }
                    };
        return $error;
    }

    my @entity_objects = ();
    foreach my $row (@rows) {

        my $input         = create_entity_input($c, $type, $row);
        my $entity_object = AssetManagerApi2::EntityFactory->new($type, $input);
        
        push @entity_objects, massage4output($entity_object);
    }

    return \@entity_objects;
}

=head3 throws_error

sets up a REST error response

IN:	Controller object
	Catalyst   object
	data structure that can be a hashref and contain error key
OUT:	undef on no errors
	array with status and message info

=cut

sub throws_error {
    my ($self, $c, $response ) = @_;

    my $error = error_exists($response);

    if ( $error ) {

        my ( $status, $message ) = ( $error->{ error }{ status }, $error->{ error }{ message } );
        $self->$status(
                            $c, 
                            message => $message,
                      );  
        $c->detach();
     }   

}


=head3 error_exists

IN:	hashref or arrayref
OUT:	undefined/error data structure 

=cut

sub error_exists {
    my ($data) = @_;

    if ( ref $data eq 'HASH' && exists $data->{ error } ) {
        return $data;
    }

    return;
}

=head3 process_csv_upload

csv file contains:
        asset name, datacentre name headers

IN:     Catalyst object
        Upload object

OUT:    on success: 1
        on error:   { error => { status => ... , message => ... } }

=cut

sub process_csv_upload {
    my ($c, $filepath) = @_; 

    my $created_categories = [];
    my $created_assets  = [];
    eval {
        my $auto = Text::CSV::Auto->new($filepath);

        my $id=0;
        $auto->process(sub { 
            my ($row) = @_;  

            my ($datacentre, $asset, $uri) = @_;

            $datacentre = create_entity($c, 'datacentre', { name => $row->{asset_datacentre} });
            die $datacentre if ref $datacentre eq 'HASH';

            $uri = $c->uri_for("/api/datacentre/id/" . $datacentre->id)->as_string;
            push @$created_categories, $uri;

            my $sanitized = _sanitize($row->{asset_name});
            $asset = $datacentre->find_or_create_related('assets', { name => $sanitized });
            die $asset if ref $asset eq 'HASH';

            $uri = $c->uri_for("/api/asset/id/" . $asset->id)->as_string;
            push @$created_assets, $uri;
        });
    };
    if ($@) {
        my $error = { error => { status  => 'status_bad_request', 
                                 message => "There were problems with processing your data: " . substr($@, 0, 250 ), }
                    };
        return $error;
    }

    return { datacentre => $created_categories, asset => $created_assets };
}

=head3 process_json_upload

json file contains an array of hashes

=cut

sub process_json_upload {
    my ($c, $fh) = @_; 

    my $created_entities = [];
    my $type = $c->stash->{ entity_type };

    eval {
        local $/; 
        binmode $fh, ':encoding(UTF-8)';

        my $encoded = <$fh>;
        chomp $encoded;

        my $data = from_json($encoded);

        for my $props (@$data) {
            my $entity   = create_entity($c, $type, $props);

            die $entity->{ message } unless blessed $entity;

            my $uri = $c->uri_for("/api/$type/id/" . $entity->id)->as_string;
            push @$created_entities, $uri;
        }
    };
    if ($@) {
        return { error => { status  => 'status_bad_request',
                            message => "There were problems with processing your data: " . substr($@, 0, 250 ), }
        }
    }

    return { $type => $created_entities };
}

=head3 create_entity

IN:     Catalyst object
        entity type
        entity properties

OUT:    response as a hashref structure:    containing a link to the created entity

=cut

sub create_entity {
    my ($c, $type, $data) = @_;

    my %sanitized = ();
    if (ref $data eq 'HASH') {
        %sanitized = map { $_ => _sanitize($data->{$_}) } keys %$data; 
    }

    my $source = type2table( $type );
    my $entity = $c->model("AssetManagerDB::$source")
                   ->find_or_create(\%sanitized);

    return $entity;
}

=head2 PRIVATE helper METHODS

    _get_properties
    _process_search_params
    _sanitize
    _transform_to_hashref

=cut

sub _get_properties {
    my ($c, $type) = @_;

    my $source = type2table( $type );
    my $table_schema  = $c->model('AssetManagerDB')->source($source);
    
    my @columns = map { { name => $_, is_rel => $table_schema->has_relationship($_) } } $table_schema->columns;
    my %column  = ();
    @column{@columns} = undef;

    my @rels        =  $table_schema->relationships;
    my @simple_rels =  grep { $_ !~ /_/ && ! exists $column{$_} } @rels;
    my @m2m_rels    =  map  { (split /_/, $_)[1] } @rels;
    @m2m_rels = (@m2m_rels) ? @m2m_rels : ();

    return (\@columns, \@simple_rels, \@m2m_rels);
}

=head2 _process_search_params

search options can come in the form of an arrayref (provided in the url)
implementation allows to potentially provide search options as a hashref
(coming from a GUI ot CLI)

allows for a direct or fuzzy search

=cut

sub _process_search_params {
    my ($c, $type, $search_option) = @_;

    $search_option = _transform_to_hashref($search_option) if ref ($search_option) eq 'ARRAY';

    my $source  = type2table( $type );
    my $schema  = $c->model('AssetManagerDB')->source($source);
    my @columns = $schema->columns;

    my $where = {};
    my $join  = [];

    for my $column (@columns) {
        if (exists $search_option->{$column}) {
            my $value = uri_unescape($search_option->{$column});
            if ($value =~ /%/) {
                $where->{"me.$column"} = { like => "$value" };
            }
            else {
                $where->{"me.$column"} = $search_option->{$column};
            }
        }
    }
    for my $field (keys $search_option) {
        my $m2m_rel = "${type}_" . PL($field);

        if ($schema->has_relationship($m2m_rel)) {
            push @$join, $m2m_rel;
            $where->{"$m2m_rel.$field"} = $search_option->{$field};
        }
    }
    my $search = { where => $where, join => { join => $join } };

    return $search;
}

sub _transform_to_hashref {
    my ($search_option) = @_;

    return $search_option unless ref ($search_option) eq 'ARRAY';

    my $transformed = {};
    while (scalar @$search_option) {
        my ($key, $value) = (shift @$search_option, shift @$search_option);
        $transformed->{$key} = $value if defined $key && defined $value;
    }

    return $transformed;
}

=head3 _sanitize

=cut

sub _sanitize {
    my $text = shift;

    return '' unless $text;    

    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    $text =~ s#[\\/<>`|!\$*()~{}'"?]+##g;        # ! $ ^ & * ( ) ~ [ ] \ | { } ' " ; < > ?
    $text =~ s/\s{2,}/ /g;

    return $text; 
}


1;
