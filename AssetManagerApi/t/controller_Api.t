use strict;
use warnings;
use Test::More;


use Catalyst::Test 'AssetManagerApi';
use AssetManagerApi::Controller::Api;

ok( request('/api')->is_success, 'Request should succeed' );
done_testing();
