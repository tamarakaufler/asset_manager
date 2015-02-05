use strict;
use warnings;

use AssetManagerApi;

my $app = AssetManagerApi->apply_default_middlewares(AssetManagerApi->psgi_app);
$app;

