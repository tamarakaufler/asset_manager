use strict;
use warnings;
use Test::More;


use Catalyst::Test 'AssetManagerApi';
use AssetManagerApi::Controller::Software;

ok( request('/software')->is_success, 'Request should succeed' );
done_testing();
