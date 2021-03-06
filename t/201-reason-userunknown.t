use strict;
use Test::More;
use lib qw(./lib ./blib/lib);
use Sisimai::Reason::UserUnknown;

my $PackageName = 'Sisimai::Reason::UserUnknown';
my $MethodNames = {
    'class' => [ 'text', 'match', 'true' ],
    'object' => [],
};

use_ok $PackageName;
can_ok $PackageName, @{ $MethodNames->{'class'} };

MAKE_TEST: {
    is $PackageName->text, 'userunknown', '->text = userunknown';
    ok $PackageName->match('550 5.1.1 Unknown User');
    is $PackageName->true, undef, '->true = undef';
}

done_testing;
