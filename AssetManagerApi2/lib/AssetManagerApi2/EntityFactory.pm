package AssetManagerApi2::EntityFactory;

use v5.018;
use utf8;
use open    ':encoding(UTF-8)';
use feature 'unicode_strings';

use FindBin qw($Bin);
use lib "$Bin/../lib";

use AssetManagerApi2::Helper::Entity qw(
                                        type2table
                                     );

=head3 new

IN: class
    hash of input params for the entity object to be created
    and c and entity type info

=cut

sub new {
    my $class = shift;

    #my $entity = type2table(shift); 
    my $entity = ucfirst shift; 

    my $path  = "AssetManagerApi2/Entity/$entity.pm";
    $class    = "AssetManagerApi2::Entity::$entity";

    require $path;
    return $class->new(@_);
};


1;
