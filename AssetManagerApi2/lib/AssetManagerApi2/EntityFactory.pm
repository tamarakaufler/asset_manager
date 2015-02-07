package AssetManagerApi2::EntityFactory;

use Moose;
use namespace::autoclean;

use v5.018;
use utf8;
use open    ':encoding(UTF-8)';
use feature 'unicode_strings';

#has 'entity' => (is      => 'ro', 
#                 isa     => 'Str',
#                 required => 1,
#                 builder => '_build_entity',
#                );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $entity = get_entity_type_from_input('entity'); 

    my $path  = "Entity/$entity.pm";
    $class    = "Entity::$entity";

    require $path;
    return $class->new('entity' => $entity);
};

#sub _build_entity { 
#    my ($self) = @_;
#
#    $self->entity(); 
#}


1;
