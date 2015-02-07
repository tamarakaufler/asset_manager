package AssetManagerApi::Controller::Helper::Api;

=head2 AssetManagerApi::Controller::Helper::Api

helper library for Controllers

=cut

use strict;
use warnings;
use v5.018;

use utf8;
use open ':encoding(UTF-8)';

use Lingua::EN::Inflect         qw(PL);
use Lingua::EN::Inflect::Number qw(to_S);
use Scalar::Util                qw(blessed);
use JSON                        qw(from_json);
use Text::CSV::Auto;
use URI::Escape;

$ENV{DBIC_TRACE} = 1;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                    get_asset_summary
                    get_listing

                    process_csv_upload
                    process_json_upload
                    create_from_inline_input

                    associate_software

                    create_entity
                    update_entity
                    delete_entity

                    throws_error
                    error_exists
                 );

# --------------------------------- PUBLIC METHODS ---------------------------------

=head2 Public methods

used by Controllers

    get_asset_summary
    get_listing

    process_csv_upload
    process_json_upload

    create_entity
    update_entity
    delete_entity

    throws_error
    error_exists

=cut


=head3 get_asset_summary

retrieves all assets and their related information
about categories and softwares

=cut

sub get_asset_summary {
    my ($c) = @_;

    my $response_data = [];
    eval {
        my $assets_rs  = $c->model('AssetManagerDB::Asset')
                              ->search({}, { prefetch => [ 'datacentre' ] });
    
        while (my $asset_data = $assets_rs->next) {
            push @$response_data, { asset => $asset_data->get_summary($c) }; 
        }

    };
    if ($@) {
        my $error = { error => { status  => 'status_bad_request', 
                                 message => "Problems with retrieving asset data: " . substr($@, 0, 250 ), }
                    };
        return $error;
    }

    return $response_data;
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

=head3 create_from_inline_input 

processes data supplied with -d/-T flags

=cut

sub create_from_inline_input {
    my ($c) = @_;

    my $data = $c->req->data;

    my $type = $c->stash->{ entity_type };
    my @rows = ();
 
    # assumes input to create one entity
    #   all it could be a requirement that the structure be always an arrayref of hashrefs
    $data = [ $data ] if ref $data eq 'HASH';

    eval {
        for my $props (@$data) {
            my $entity = create_entity($c, $type, $props);
            push @rows, $entity;
        }
    };
    if ($@) {
        my $error = { error => { status  => 'status_bad_request', 
                                 message => "Problems with processing input data: " . substr($@, 0, 250 ), }
                    };
        return $error;
    }

    my $response_data = _massage4output($c, $c->stash->{ entity_type }, \@rows);
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
    my $source = _type2table( $type );
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

    my $entities = _massage4output($c, $type, \@rows);
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

    my $source = _type2table( $type );
    my $entity = $c->model("AssetManagerDB::$source")
                   ->find_or_create(\%sanitized);

    return $entity;
}

sub update_entity {
    my ($c, $type, $data) = @_;
}

sub delete_entity {
    my ($c, $type, $id) = @_;
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

=head2 associate_software

=cut

sub associate_software {
    my ($c) = @_;

    my $tagging_data;

    if ($c->req->data) {
        $tagging_data = $c->req->data;
    }
    else {
        my $error = { error => { status  => 'status_bad_request', 
                                 message => "Problems with tagging clothes: no data received" }
                    };
        return $error;
    }

    if ( not exists $tagging_data->{ asset } || not exists $tagging_data->{ software }) {
        my $error = { error => { status  => 'status_bad_request', 
                                 message => "Problems with tagging clothes: " . substr($@, 0, 250 ), }
                    };
        return $error;
    }

    my ($tagging, $asset, $software);

    eval {
        my $input   = { asset => $tagging_data->{'asset'}, software => $tagging_data->{'software'}};
        
        $asset = $c->model("AssetManagerDB::Asset")->find($input->{ asset });
        $software = $c->model("AssetManagerDB::Software")->find($input->{ software });

        if ($asset && $software) {
            $tagging = $c->model("AssetManagerDB::AssetSoftware")->create($input);
        }
    };
    if ($@ || ! $tagging) {
        $@ = "Supplied asset and/or software do not exist" unless $@;

        my $error = { error => { status  => 'status_bad_request', 
                                 message => "Problems with tagging clothes: " . substr($@, 0, 250 ), }
                    };
        return $error;
    }

    return  { location => $c->uri_for("/api/asset_software/id/" . $tagging->id) };
}

# --------------------------------- PRIVATE METHODS ---------------------------------

=head3 Private methods

    _massage4output 
    _get_properties 
    _process_search_params 
    _transform_to_hashref 

=cut

sub _massage4output {
    my ($c, $type, $rows) = @_;

    my @massaged   = ();
    my ($properties, $m2m_rels) = _get_properties($c, $type);

    for my $row (@$rows) {
        my %massaged = ();

        my $uri = $c->uri_for("/api/$type/id/" . $row->id)->as_string;
        $massaged{link} = $uri;

        ## TODO: extract into a separate sub
        for my $prop (@$properties) {
            my $column = $prop->{name};

            if ($prop->{is_rel}) {
                my $source = _type2table( $column );
                my $rel_schema  = $c->model('AssetManagerDB')->source($source);
            
                my @rel_columns = $rel_schema->columns;
                $massaged{properties}{$column} = { map { $_ => $row->$column->$_ } @rel_columns };

                $uri = $c->uri_for("/api/$column/id/" . $row->$column->id)->as_string;
                $massaged{properties}{$column}{link} = $uri;
            }
            else {
                $massaged{properties}{$column} = $row->$column;
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

            # all the associated relationships of this type with this $row
            
            my @rels = $row->$rel_name; 

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

        push @massaged, \%massaged;
    }


    return \@massaged;
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

=head2 _process_search_params

search options can come in the form of an arrayref (provided in the url)
implementation allows to potentially provide search options as a hashref
(coming from a GUI ot CLI)

allows for a direct or fuzzy search

=cut

sub _process_search_params {
    my ($c, $type, $search_option) = @_;

    $search_option = _transform_to_hashref($search_option) if ref ($search_option) eq 'ARRAY';

    my $source = _type2table( $type );
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

=head3 _type2table

derives DBIx Source from  the table
TODO: through introspection

=cut

sub _type2table {
    my ($type) = @_;

    return ucfirst $type unless $type =~ /_/;

    $type = join '', map { ucfirst $_ } split /_/, $type ;
}

1;
