use strict;
use warnings;

use AssetManagerApi2;

my $app = AssetManagerApi2->apply_default_middlewares(AssetManagerApi2->psgi_app);
$app;

