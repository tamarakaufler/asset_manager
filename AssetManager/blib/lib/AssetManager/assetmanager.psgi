use strict;
use warnings;

use AssetManager;

my $app = AssetManager->apply_default_middlewares(AssetManager->psgi_app);
$app;

