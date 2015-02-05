use strict;
use warnings;
use Test::More;


use Catalyst::Test 'AssetManagerApi';
use AssetManagerApi::Controller::Docs;

ok( request('/docs')->is_success, 'Request should succeed' );
done_testing();
