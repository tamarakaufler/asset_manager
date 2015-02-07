use strict;
use warnings;
use Test::More;


use Catalyst::Test 'AssetManagerApi2';
use AssetManagerApi2::Controller::Entity;

ok( request('/entity')->is_success, 'Request should succeed' );
done_testing();
