#!/usr/bin/perl -T

=pod 

=head1 manager.cgi

script for online management of assets:

=head2 Provides following functionalities

=over 4

=item search by name of a asset

=item adding assets to the database through an uploaded csv file

=item associating assets with software

=item adding new software

=back

=head2 Required modules

=over 4

=item CGI

=item Template

=item Controller::Manager

=item Controller::Helper

=back

=cut 

use strict;
use warnings;
use v5.018;
use lib qw( lib );

use CGI;
use Template;
use CGI::Carp qw( fatalsToBrowser warningsToBrowser );
use utf8;
use open ':encoding(utf8)';

use Controller::Manager;
use Controller::Helper;

## TT variables for display of informative/error messages
my $tt_vars = {};
$tt_vars->{ title } = 'Asset Manager';

my $cgi     = CGI->new();
## limit file uploads
$CGI::POST_MAX = 1024 * 5000;    # 5 Mb

my $manager = Controller::Manager->new();
my $tt      = Template->new(
                            {
                                INCLUDE_PATH => 'lib/View',
                                WRAPPER      => 'wrapper.tt',
                            }
                          ) || die Template->error();

my $mode = sanitize($cgi->param( 'mode' ));    
$tt_vars->{ mode } = $mode;

print $cgi->header(-charset=>'utf-8');

## actions to support business requirements
if ( $mode eq 'search' ) {

    ( $tt_vars->{ assets },
      $tt_vars->{ softwares } ) = massage4output($manager->search( $cgi->param( 'asset_name' )));

} elsif( $mode eq 'upload' ) {
    $manager->upload($cgi);

} elsif( $mode eq 'associate' ) {
    $manager->associate($cgi);

} elsif( $mode eq 'add_software' ) {
    $manager->add_software($cgi->param( 'software_name' ));

}

## Display the page
$tt_vars->{ message } = $manager->{ message };
$tt_vars->{ error }   = $manager->{ error };
$tt->process('index.tt', $tt_vars) or die Template->error();


