#!/usr/bin/perl

=head1 NAME

manager.t

=head2 SYNOPSIS

in the parent dir of t dir:
                            prove t/manager.t
                            make test

=head2 DESCRIPTION

test for the Controller::Manager module

=cut

use strict;
use warnings;
use utf8;

use lib qw( ./lib ../lib );
use 5.10.0;

use Test::More tests => '24';
use Test::MockObject::Extends;

use DBI;
use CGI;
use Data::Dumper qw( Dumper );

my $dbh = DBI->connect('dbi:mysql:dbname=assetmanager', 'assetmanager', 'test');
{
    local $/ = ";\n";
    ## make sure NO BLANK LINES are present in the DATA section, otherwise MySQL will complain
    $dbh->do( $_ ) while <DATA>;
}

my $module = 'Controller::Manager';
use_ok($module);

my $manager = $module->new();

isa_ok($manager, $module);
can_ok($manager, 'new');
can_ok($manager, 'search');
can_ok($manager, 'upload');
can_ok($manager, 'associate');
can_ok($manager, 'add_software');

## search method
##--------------

## search for a word in the asset name
my @search_results = $manager->search( 'Fast', 1 );
is(scalar @search_results, 2, 'Search for "Fast" returned 2 arrayrefs');
# asset
is(scalar @{$search_results[0]}, 2, 'Search for "Fast" returned 2 items of asset');
# software
is(scalar @{$search_results[1]}, 6, 'Search for "Fast" returned 6 softwares');

my $asset = $search_results[0]->[0];
is($asset->datacentre->name, 'London', 'Asset item datacentre retrieved correctly');

my @softwares = $asset->softwares;
is(scalar @softwares, 0 , 'No softwares');

## search to pull out every item of asset
@search_results = $manager->search( '', 1 );
# asset
is(scalar @{$search_results[0]}, 9, 'Search returned 9 items of asset');
# software
is(scalar @{$search_results[1]}, 6, 'Search returned 6 softwares');

$asset = $search_results[0]->[0];
is($asset->name, 'Elégant Server 1', 'Asset item retrieved correctly');
$asset = $search_results[0]->[3];
is($asset->name, 'Server 2', 'Asset item retrieved correctly');

is($asset->datacentre->name, 'Prague', 'Asset item datacentre retrieved correctly');

my $software = $search_results[1]->[2];
is($software->name, 'Casual software 3', 'Software retrieved correctly');

## associate method
##-----------

my $cgi = CGI->new();
$cgi = Test::MockObject::Extends->new( $cgi );
isa_ok($cgi, 'CGI', 'mock $cgi is CGI object');

$cgi->mock( 'param', sub { 
                              my $field = shift; 
                              if ( $field eq 'asset' ) {
                                return '6';
                              } else {
                                return (4,5,6);
                              }
                         } );
$asset = $search_results[0]->[7];
is($asset->name, 'Server 6', 'Asset item retrieved correctly');
is($asset->id, 6, 'Asset id 6');
$manager->associate( $cgi, 1 );
@softwares = $asset->softwares;
is(scalar @softwares, 3 , 'Asset belongs to 3 softwares now');

## upload method
##--------------

my $upload_file;
if ( -e './documents/asset.csv' ) {
    $upload_file = './documents/asset.csv';
} elsif ( -e '../documents/asset.csv' ) {
    $upload_file = '../documents/asset.csv';
} else {
    die "Cannot find cvs upload file => dying";
}

$cgi->mock( 'param'       , sub { shift; return $upload_file } );
$cgi->mock( 'uploadInfo'  , sub { shift; return { 'Content-Type' => 'text/csv' } } );
$cgi->mock( 'tmpFileName' , sub { shift; return $upload_file } );

#--------------------------------------------------
# $cgi = CGI->new({ 
#                      file => "$upload_file",
#                       $upload_file => { 'Content-Type' => 'text/csv' },
#                 });
#-------------------------------------------------- 

$manager->upload( $cgi, 1 );
## search to pull out every item of asset
@search_results = $manager->search( '', 1 );
# asset
is(scalar @{$search_results[0]}, 18, 'Search returned 18 items of asset after upload');

## add_software method
##------------------

$manager->add_software( 'Test software', 1 );
@softwares = $manager->schema
                   ->resultset('SoftwareTest')
                   ->search(); 
is(scalar @softwares, 7, 'Number of softwares is 7 after adding one')


__END__
START TRANSACTION;
    DROP TABLE IF EXISTS asset_test;
    DROP TABLE IF EXISTS datacentre_test;
    DROP TABLE IF EXISTS software_test;
    DROP TABLE IF EXISTS asset_software_test;
    CREATE TABLE datacentre_test (
           id          INT  NOT NULL PRIMARY KEY AUTO_INCREMENT,
           name        VARCHAR(255) NOT NULL,
           INDEX (name)
    ) ENGINE=InnoDB;
    CREATE TABLE asset_test (
           id          INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
           name        VARCHAR(255) NOT NULL,
           datacentre  INT NOT NULL,
           FOREIGN KEY (datacentre) references datacentre_test(id),
           INDEX (name)
    ) ENGINE=InnoDB;
    CREATE TABLE software_test (
           id          INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
           name        VARCHAR(255) NOT NULL,
           INDEX (name)
    ) ENGINE=InnoDB;
    CREATE TABLE asset_software_test (
           asset     INT NOT NULL,
           software  INT NOT NULL,
           PRIMARY KEY (asset, software)
    ) ENGINE=InnoDB;
    INSERT INTO `datacentre_test` VALUES (1,'Prague'),(3,'Paris'),(5,'London'),(4,'New York'),(2,'Sidney');
    INSERT INTO `asset_test` VALUES (1,'Server 2',1),(2,'Server 1',2),(3,'Nice™ Server 1',2),(4,'Server 4',3),(5,'Server 5',4),(6,'Server 6',4),(7,'Fast Server 7',5),(8,'Fast Server 8',5),(9,'Elégant Server 1',5);
    INSERT INTO software_test VALUES (NULL, 'Casual software 1');
    INSERT INTO software_test VALUES (NULL, 'Casual software 2');
    INSERT INTO software_test VALUES (NULL, 'Casual software 3');
    INSERT INTO software_test VALUES (NULL, 'Smart software 1');
    INSERT INTO software_test VALUES (NULL, 'Smart software 2');
    INSERT INTO software_test VALUES (NULL, 'Smart software 3');
COMMIT;
