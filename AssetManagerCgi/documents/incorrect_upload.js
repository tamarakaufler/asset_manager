#!/usr/bin/perl
# Difference between Javascript and Perl closures

# Javascript - this will print out 1, because all js functions are closures  
#--------------------------------------------------
# (function(){
#  var a=1;
#  return function(x){
#  	eval(x)
#  }
#  })()("alert(a)")
#-------------------------------------------------- 

# Perl ... this will not print anything, because the anonymous subroutine is not a closure
#--------------------------------------------------
sub {
	my $a = 1;
	sub { eval $_[0] };
}->()('print "* $a"');

# Perl ... this will print 2, because the anonymous subroutine is a closure
#--------------------------------------------------
sub {
	my $a = 2;
	sub { $a; eval $_[0]};
}->()('print "** $a"');
