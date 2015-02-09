package AssetManager::View::Web;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
    WRAPPER    => 'wrapper.tt',
    ENCODING   => 'utf-8',
);

=head1 NAME

AssetManager::View::Web - TT View for AssetManager

=head1 DESCRIPTION

TT View for AssetManager.

=head1 SEE ALSO

L<AssetManager>

=head1 AUTHOR

Tamara Kaufler,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
