#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.04';
$DATE = '2003/06/19';

use Cwd;
use File::Spec;
use File::FileUtil;
use Test;

######
#
# T:
#
# use a BEGIN block so we print our plan before Module Under Test is loaded
#
BEGIN { 
   use vars qw($__restore_dir__ @__restore_inc__ $__tests__);

   ########
   # Create the test plan by supplying the number of tests
   # and the todo tests
   #
   $__tests__ = 8;
   plan(tests => $__tests__);

   ########
   # Working directory is that of the script file
   #
   $__restore_dir__ = cwd();
   my ($vol, $dirs, undef) = File::Spec->splitpath( $0 );
   chdir $vol if $vol;
   chdir $dirs if $dirs;

   #######
   # Add the library of the unit under test (UUT) to @INC
   #
   my $work_dir = cwd();
   ($vol,$dirs) = File::Spec->splitpath( $work_dir, 'nofile');
   my @dirs = File::Spec->splitdir( $dirs );
   while( $dirs[-1] ne 't' ) { 
       chdir File::Spec->updir();
       pop @dirs;
   };
   @__restore_inc__ = @INC;
   unshift @INC, cwd();  # include the current test directory
   chdir File::Spec->updir();
   my $lib_dir = File::Spec->catdir( cwd(), 'lib' );
   unshift @INC, $lib_dir;
   chdir $work_dir;

}

END {

    #########
    # Restore working directory and @INC back to when enter script
    #
    @INC = @__restore_inc__;
    chdir $__restore_dir__;
}

#######
# Create a File::FileUtil object
#
my $fu = 'File::FileUtil';
my $su = 'Test::STD::STDutil';

####
#
# ok: 1
#
# R:
#
print "# UUT not loaded.\n";
my $loaded = $fu->is_package_loaded('Test::STD::STDutil');
ok( $loaded, ''); # actual results

####
#
# ok: 2
#
# R:
#
print "# Load UUT.\n";
my $errors = $fu->load_package( 'Test::STD::STDutil' );
skip($loaded, $errors,'');
skip_rest( $errors, 2 );
 
####
#
# ok: 3
#
# R:
#
print "# No pod errors\n";
ok( $fu->pod_errors( 'Test::STD::STDutil'), 0);

####
#
# ok: 4
#
# R:
#
print "# replace variables\n";

my $template = << 'EOF';
=head1 Title Page

 Software Version Description

 for

 ${TITLE}

 Revision: ${REVISION}

 Version: ${VERSION}

 Date: ${DATE}

 Prepared for: ${END_USER} 

 Prepared by:  ${AUTHOR}

 Copyright: ${COPYRIGHT}

 Classification: ${CLASSIFICATION}

=cut

EOF

my %variables = (
   TITLE => 'SVDmaker',
   REVISION => '-',
   VERSION => '0.01',
   DATE => '1969/5/6',
   END_USER => 'General Public',
   AUTHOR => 'Software Diamonds',
   COPYRIGHT => 'none',
   CLASSIFICATION => 'none');

$su->replace_variables( \$template, \%variables );

my $expected_template = << 'EOF';
=head1 Title Page

 Software Version Description

 for

 SVDmaker

 Revision: -

 Version: 0.01

 Date: 1969/5/6

 Prepared for: General Public 

 Prepared by:  Software Diamonds

 Copyright: none

 Classification: none

=cut

EOF

ok( $template, $expected_template);


####
#
# ok: 5
#
# R:
#
print "# get_date\n";
my $date = $su->get_date();
ok( $date =~ m=2\d\d\d/\d\d/\d\d=, '1');




####
#
# ok: 6
#
# R:
#
print "# format_array_table\n";

my @array_table =  (
   [qw(module.pm 0.01 2003/5/6 new)],
   [qw(bin/script.pl 1.04 2003/5/5 generated)],
   [qw(bin/script.pod 3.01 2003/6/8), 'revised 2.03']
);

my $expected_table = << 'EOF';
 file            version date       comment
 --------------- ------- ---------- ---------------
 module.pm       0.01    2003/5/6   new
 bin/script.pl   1.04    2003/5/5   generated
 bin/script.pod  3.01    2003/6/8   revised 2.03
EOF

ok($su->format_array_table(\@array_table, [15,7,10,15],[qw(file version date comment)]),
     $expected_table);

####
#
# ok: 7
#
# R:
#
print "# format_hash_table - hash of array\n";

my %hash_table =  (
   'module.pm' => [qw(0.01 2003/5/6 new)],
   'bin/script.pl' => [qw(1.04 2003/5/5 generated)],
   'bin/script.pod' => [qw(3.01 2003/6/8), 'revised 2.03']
);

$expected_table = << 'EOF';
 file            version date       comment
 --------------- ------- ---------- ---------------
 bin/script.pl   1.04    2003/5/5   generated
 bin/script.pod  3.01    2003/6/8   revised 2.03
 module.pm       0.01    2003/5/6   new
EOF

ok($su->format_hash_table(\%hash_table, [15,7,10,15],[qw(file version date comment)]),
     $expected_table);

####
#
# ok: 8
#
# R:
#
print "# format_hash_table - hash of hash\n";

%hash_table =  (
   'L<test1>' => {'L<requirement4>' => undef, 'L<requirement1>' => undef },
   'L<test2>' => {'L<requirement3>' => undef },
   'L<test3>' => {'L<requirement2>' => undef, 'L<requirement1>' => undef },
);

$expected_table = << 'EOF';
 test                 requirement
 -------------------- --------------------
 L<test1>             L<requirement1>
 L<test1>             L<requirement4>
 L<test2>             L<requirement3>
 L<test3>             L<requirement1>
 L<test3>             L<requirement2>
EOF

ok($su->format_hash_table(\%hash_table, [20,20],[qw(test requirement)]),
    $expected_table);

####
# 
# Support:
#
# The ok user caller to look up the stack. If nothing there,
# ok produces a warining. Thus, burying it in a subroutine eliminates
# these warning.
#

sub skip_rest
{
    my ($results, $test_num) = @_;
    if( $results ) {
        for (my $i=$test_num; $i < $__tests__; $i++) { skip(1,0,0) };
        exit 1;
    }
}


__END__


=head1 NAME

tester.t - test script for Test::Tester

=head1 SYNOPSIS

 tester.t 

=head1 COPYRIGHT

copyright © 2003 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

## end of test script file ##

