use strict;
use Test::More;
use lib qw(./lib ./blib/lib);
use Sisimai::Data;
use Sisimai::Mail;
use Sisimai::Message;

my $PackageName = 'Sisimai::Data';
my $MethodNames = {
    'class' => [ 'new', 'make' ],
    'object' => [ 'damn' ],
};

use_ok $PackageName;
can_ok $PackageName, @{ $MethodNames->{'class'} };

MAKE_TEST: {
    is $PackageName->make, undef;
    is $PackageName->new, undef;

    my $file = './eg/maildir-as-a-sample/new/sendmail-03.eml';
    my $mail = Sisimai::Mail->new( $file );
    my $mesg = undef;
    my $data = undef;
    my $list = undef;

    while( my $r = $mail->read ){ 
        $mesg = Sisimai::Message->new( 'data' => $r ); 
        $data = Sisimai::Data->make( 'data' => $mesg ); 
        isa_ok $data, 'ARRAY';

        for my $e ( @$data ) {
            isa_ok $e, $PackageName;
            ok length $e->token, 'token = '.$e->token;
            ok length $e->lhost, 'lhost = '.$e->lhost;
            ok length $e->rhost, 'rhost = '.$e->rhost;
            like $e->alias, qr/\A.+[@].+[.].+\z/, 'alias = '.$e->alias;
            ok defined $e->listid, 'listid = '.$e->listid;
            is $e->reason, 'userunknown', 'reason = '.$e->reason;
            ok length $e->subject, 'subject = '.$e->subject;

            isa_ok $e->timestamp, 'Time::Piece';
            is $e->timestamp->year, 2014, 'timestamp->year = '.$e->timestamp->year;
            is $e->timestamp->month, 'Jun', 'timestamp->month = '.$e->timestamp->month;
            is $e->timestamp->mday, 21, 'timestamp->mday = '.$e->timestamp->mday;
            is $e->timestamp->day, 'Sat', 'timestamp->day = '.$e->timestamp->day;

            isa_ok $e->addresser, 'Sisimai::Address';
            ok length $e->addresser->host, 'addresser->host = '.$e->addresser->host;
            ok length $e->addresser->user, 'addresser->user = '.$e->addresser->user;
            ok length $e->addresser->address, 'addresser->address = '.$e->addresser->address;
            is $e->addresser->host, $e->senderdomain, 'senderdomain = '.$e->senderdomain;

            isa_ok $e->recipient, 'Sisimai::Address';
            ok length $e->recipient->host, 'recipient->host = '.$e->recipient->host;
            ok length $e->recipient->user, 'recipient->user = '.$e->recipient->user;
            ok length $e->recipient->address, 'recipient->address = '.$e->recipient->address;
            is $e->recipient->host, $e->destination, 'destination = '.$e->destination;

            ok length $e->messageid, 'messageid = '.$e->messageid;
            is $e->smtpagent, 'Sendmail', 'smtpagent = '.$e->smtpagent;
            is $e->smtpcommand, 'DATA', 'smtpcommand = '.$e->smtpcommand;

            ok length $e->diagnosticcode, 'diagnosticcode = '.$e->diagnosticcode;
            ok length $e->diagnostictype, 'diagnostictype = '.$e->diagnostictype;
            like $e->deliverystatus, qr/\A\d+[.]\d+[.]\d\z/, 'deliverystatus = '.$e->deliverystatus;
            like $e->timezoneoffset, qr/\A[+-]\d+\z/, 'timezoneoffset = '.$e->timezoneoffset;

            ok defined $e->feedbacktype, 'feedbacktype = '.$e->feedbacktype;
            ok defined $e->action, 'action = '.$e->action;
        }
    }

    $file = './eg/maildir-as-a-sample/new/sendmail-04.eml';
    $mail = Sisimai::Mail->new( $file );
    $list = { 
        'recipient' => [ 'X-Failed-Recipient', 'To' ],
        'addresser' => [ 'Return-Path', 'From', 'X-Envelope-From' ],
    };

    WITH_ORDER: while( my $r = $mail->read ){ 
        $mesg = Sisimai::Message->new( 'data' => $r ); 
        $data = Sisimai::Data->make( 'data' => $mesg, 'order' => $list ); 
        isa_ok $data, 'ARRAY';

        for my $e ( @$data ) {
            isa_ok $e, $PackageName;
            ok length $e->token, 'token = '.$e->token;
            ok length $e->lhost, 'lhost = '.$e->lhost;
            ok length $e->rhost, 'rhost = '.$e->rhost;
            ok defined $e->listid, 'listid = '.$e->listid;
            is $e->reason, 'rejected', 'reason = '.$e->reason;
            ok length $e->subject, 'subject = '.$e->subject;

            isa_ok $e->timestamp, 'Time::Piece';
            is $e->timestamp->year, 2009, 'timestamp->year = '.$e->timestamp->year;
            is $e->timestamp->month, 'Apr', 'timestamp->month = '.$e->timestamp->month;
            is $e->timestamp->mday, 29, 'timestamp->mday = '.$e->timestamp->mday;
            is $e->timestamp->day, 'Wed', 'timestamp->day = '.$e->timestamp->day;

            isa_ok $e->addresser, 'Sisimai::Address';
            ok length $e->addresser->host, 'addresser->host = '.$e->addresser->host;
            ok length $e->addresser->user, 'addresser->user = '.$e->addresser->user;
            ok length $e->addresser->address, 'addresser->address = '.$e->addresser->address;
            is $e->addresser->host, $e->senderdomain, 'senderdomain = '.$e->destination;

            isa_ok $e->recipient, 'Sisimai::Address';
            ok length $e->recipient->host, 'recipient->host = '.$e->recipient->host;
            ok length $e->recipient->user, 'recipient->user = '.$e->recipient->user;
            ok length $e->recipient->address, 'recipient->address = '.$e->recipient->address;
            is $e->recipient->host, $e->destination, 'destination = '.$e->destination;

            ok length $e->messageid, 'messageid = '.$e->messageid;
            is $e->smtpagent, 'Sendmail', 'smtpagent = '.$e->smtpagent;
            is $e->smtpcommand, 'MAIL', 'smtpcommand = '.$e->smtpcommand;

            ok length $e->diagnosticcode, 'diagnosticcode = '.$e->diagnosticcode;
            ok length $e->diagnostictype, 'diagnostictype = '.$e->diagnostictype;
            like $e->deliverystatus, qr/\A\d+[.]\d+[.]\d\z/, 'deliverystatus = '.$e->deliverystatus;
            like $e->timezoneoffset, qr/\A[+-]\d+\z/, 'timezoneoffset = '.$e->timezoneoffset;

            ok defined $e->feedbacktype, 'feedbacktype = '.$e->feedbacktype;
        }
    }

    $file = './eg/maildir-as-a-sample/tmp/is-not-bounce-01.eml';
    $mail = Sisimai::Mail->new( $file );

    NOT_BOUNCE: while( my $r = $mail->read ){ 
        $mesg = Sisimai::Message->new( 'data' => $r ); 
        is $mesg, undef;
    }
}
done_testing;
