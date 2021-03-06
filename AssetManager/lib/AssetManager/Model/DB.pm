package AssetManager::Model::DB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'AssetManager::Schema',
    
    connect_info => {
        dsn => 'dbi:mysql:assetmanager',
        user => 'assetmanager',
        password => 'StRaW101',
        mysql_enable_utf8 => 1,
    }
);

=head1 NAME

AssetManager::Model::DB - Catalyst DBIC Schema Model

=head1 SYNOPSIS

See L<AssetManager>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<AssetManager::Schema>

=head1 GENERATED BY

Catalyst::Helper::Model::DBIC::Schema - 0.61

=head1 AUTHOR

Tamara Kaufler

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
