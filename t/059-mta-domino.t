use strict;
use Test::More;
use lib qw(./lib ./blib/lib);
use Sisimai::MTA::Domino;

my $PackageName = 'Sisimai::MTA::Domino';
my $MethodNames = {
    'class' => [ 
        'version', 'description', 'headerlist', 'scan',
        'SMTPCOMMAND', 'DELIVERYSTATUS', 'RFC822HEADERS',
    ],
    'object' => [],
};

use_ok $PackageName;
can_ok $PackageName, @{ $MethodNames->{'class'} };

MAKE_TEST: {
    my $v = undef;

    $v = $PackageName->version;
    ok $v, '->version = '.$v;
    $v = $PackageName->description;
    ok $v, '->description = '.$v;

    $v = $PackageName->smtpagent;
    ok $v, '->smtpagent = '.$v;

    is $PackageName->scan, undef, '->scan';

    use Sisimai::Mail;
    use Sisimai::Message;

    PARSE_EACH_MAIL: for my $n ( 1..10 ) {

        my $emailfn = sprintf( "./eg/maildir-as-a-sample/new/domino-%d.eml", $n );
        my $mailbox = Sisimai::Mail->new( $emailfn );
        next unless defined $mailbox;

        while( my $r = $mailbox->read ) {

            my $p = Sisimai::Message->new( 'data' => $r );
            isa_ok $p, 'Sisimai::Message';
            isa_ok $p->ds, 'ARRAY';
            isa_ok $p->header, 'HASH';
            isa_ok $p->rfc822, 'HASH';
            ok length $p->from;

            for my $e ( @{ $p->ds } ) {
                is $e->{'spec'}, 'SMTP', '->spec = SMTP';
                ok length $e->{'recipient'}, '->recipient = '.$e->{'recipient'};
                like $e->{'status'}, qr/\d[.]\d[.]\d+/, '->status = '.$e->{'status'};
                ok defined $e->{'reason'}, '->reason = '.$e->{'reason'};
                is $e->{'feedbacktype'}, '', '->feedbacktype = ""';
                ok defined $e->{'command'}, '->command = '.$e->{'command'};
                ok length $e->{'date'}, '->date = '.$e->{'date'};
                ok length $e->{'diagnosis'}, '->diagnosis = '.$e->{'diagnosis'};
                ok length $e->{'action'}, '->action = '.$e->{'action'};
                ok defined $e->{'rhost'}, '->rhost = '.$e->{'rhost'};
                ok length $e->{'lhost'}, '->lhost = '.$e->{'lhost'};
                ok defined $e->{'alias'}, '->alias = '.$e->{'alias'};
                is $e->{'agent'}, 'Domino', '->agent = '.$e->{'agent'};
            }
        }
    }
}
done_testing;
