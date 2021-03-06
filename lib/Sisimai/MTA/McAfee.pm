package Sisimai::MTA::McAfee;
use parent 'Sisimai::MTA';
use feature ':5.10';
use strict;
use warnings;

my $RxMTA = {
    'begin'   => qr/[-]+ The following addresses had delivery problems [-]+\z/,
    'error'   => qr|\AContent-Type: [^ ]+/[^ ]+; name="deliveryproblems[.]txt"|,
    'rfc822'  => qr|\AContent-Type: message/rfc822\z|,
    'endof'   => qr/\A__END_OF_EMAIL_MESSAGE__\z/,
    'x-nai'   => qr/Modified by McAfee /,
    'subject' => qr/\ADelivery Status\z/,
};

my $RxErr = {
    'userunknown' => [
        qr/User [(].+[@].+[)] unknown[.]/,
        qr/550 Unknown user [^ ]+[@][^ ]+/,
    ],
};

sub version     { '4.0.2' }
sub description { 'McAfee Email Appliance' }
sub smtpagent   { 'McAfee' }
sub headerlist  { return [ 'X-NAI-Header' ] }

sub scan {
    # @Description  Detect an error from McAfee
    # @Param <ref>  (Ref->Hash) Message header
    # @Param <ref>  (Ref->String) Message body
    # @Return       (Ref->Hash) Bounce data list and message/rfc822 part
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;

    return undef unless $mhead->{'x-nai-header'};
    return undef unless $mhead->{'x-nai-header'} =~ $RxMTA->{'x-nai'};
    return undef unless $mhead->{'subject'}      =~ $RxMTA->{'subject'};

    my $dscontents = [];    # (Ref->Array) SMTP session errors: message/delivery-status
    my $rfc822head = undef; # (Ref->Array) Required header list in message/rfc822 part
    my $rfc822part = '';    # (String) message/rfc822-headers part
    my $rfc822next = { 'from' => 0, 'to' => 0, 'subject' => 0 };
    my $previousfn = '';    # (String) Previous field name

    my $stripedtxt = [ split( "\n", $$mbody ) ];
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $diagnostic = '';    # (String) Alternative diagnostic message

    my $v = undef;
    my $p = '';
    push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
    $rfc822head = __PACKAGE__->RFC822HEADERS;

    require Sisimai::Address;

    for my $e ( @$stripedtxt ) {
        # Read each line between $RxMTA->{'begin'} and $RxMTA->{'rfc822'}.
        if( ( $e =~ $RxMTA->{'rfc822'} ) .. ( $e =~ $RxMTA->{'endof'} ) ) {
            # After "message/rfc822"
            if( $e =~ m/\A([-0-9A-Za-z]+?)[:][ ]*(.+)\z/ ) {
                # Get required headers only
                my $lhs = $1;
                my $rhs = $2;

                $previousfn = '';
                next unless grep { lc( $lhs ) eq lc( $_ ) } @$rfc822head;

                $previousfn  = $lhs;
                $rfc822part .= $e."\n";

            } elsif( $e =~ m/\A[\s\t]+/ ) {
                # Continued line from the previous line
                next if $rfc822next->{ lc $previousfn };
                $rfc822part .= $e."\n" if $previousfn =~ m/\A(?:From|To|Subject)\z/;

            } else {
                # Check the end of headers in rfc822 part
                next unless $previousfn =~ m/\A(?:From|To|Subject)\z/;
                next unless $e =~ m/\A\z/;
                $rfc822next->{ lc $previousfn } = 1;
            }

        } else {
            # Before "message/rfc822"
            next unless ( $e =~ $RxMTA->{'begin'} ) .. ( $e =~ $RxMTA->{'rfc822'} );
            next unless length $e;

            # Content-Type: text/plain; name="deliveryproblems.txt"
            #
            #    --- The following addresses had delivery problems ---
            #
            # <user@example.com>   (User unknown user@example.com)
            #
            # --------------Boundary-00=_00000000000000000000
            # Content-Type: message/delivery-status; name="deliverystatus.txt"
            #
            $v = $dscontents->[ -1 ];

            if( $e =~ m{\A[<]([^ ]+[@][^ ]+)[>][\s\t]+[(](.+)[)]\z} ) {
                # <kijitora@example.co.jp>   (Unknown user kijitora@example.co.jp)
                if( length $v->{'recipient'} ) {
                    # There are multiple recipient addresses in the message body.
                    push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                    $v = $dscontents->[ -1 ];
                }
                $v->{'recipient'} = $1;
                $diagnostic = $2;
                $recipients++;

            } elsif( $e =~ m/\AOriginal-Recipient:[ ]*([^ ]+)\z/i ) {
                # Original-Recipient: <kijitora@example.co.jp>
                $v->{'alias'} = Sisimai::Address->s3s4( $1 );

            } elsif( $e =~ m/\AAction:[ ]*(.+)\z/i ) {
                # Action: failed
                $v->{'action'} = lc $1;

            } elsif( $e =~ m/\ARemote-MTA:[ ]*(.+)\z/i ) {
                # Remote-MTA: 192.0.2.192
                $v->{'rhost'} = lc $1;

            } else {

                if( $e =~ m/\ADiagnostic-Code:[ ]*(.+?);[ ]*(.+)\z/i ) {
                    # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                    $v->{'spec'} = uc $1;
                    $v->{'diagnosis'} = $2;

                } elsif( $p =~ m/\ADiagnostic-Code:[ ]*/i && $e =~ m/\A[\s\t]+(.+)\z/ ) {
                    # Continued line of the value of Diagnostic-Code header
                    $v->{'diagnosis'} .= ' '.$1;
                    $e = 'Diagnostic-Code: '.$e;
                }
            }
        } # End of if: rfc822

    } continue {
        # Save the current line for the next loop
        $p = $e;
        $e = '';
    }

    return undef unless $recipients;
    require Sisimai::String;
    require Sisimai::RFC5322;

    for my $e ( @$dscontents ) {
        # Set default values if each value is empty.
        $e->{'agent'} ||= __PACKAGE__->smtpagent;

        if( scalar @{ $mhead->{'received'} } ) {
            # Get localhost and remote host name from Received header.
            my $r = $mhead->{'received'};
            $e->{'lhost'} ||= shift @{ Sisimai::RFC5322->received( $r->[0] ) };
            $e->{'rhost'} ||= pop @{ Sisimai::RFC5322->received( $r->[-1] ) };
        }
        $e->{'diagnosis'} = Sisimai::String->sweep( $e->{'diagnosis'} || $diagnostic );

        SESSION: for my $r ( keys %$RxErr ) {
            # Verify each regular expression of session errors
            PATTERN: for my $rr ( @{ $RxErr->{ $r } } ) {
                # Check each regular expression
                next(PATTERN) unless $e->{'diagnosis'} =~ $rr;
                $e->{'reason'} = $r;
                last(SESSION);
            }
        }

        $e->{'status'} = Sisimai::RFC3463->getdsn( $e->{'diagnosis'} );
        $e->{'spec'}   = $e->{'reason'} eq 'mailererror' ? 'X-UNIX' : 'SMTP';
    }
    return { 'ds' => $dscontents, 'rfc822' => $rfc822part };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::MTA::McAfee - bounce mail parser class for C<McAfee Email Appliance>.

=head1 SYNOPSIS

    use Sisimai::MTA::McAfee;

=head1 DESCRIPTION

Sisimai::MTA::McAfee parses a bounce email which created by C<McAfee Email
Appliance>. Methods in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<version()>>

C<version()> returns the version number of this module.

    print Sisimai::MTA::McAfee->version;

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::MTA::McAfee->description;

=head2 C<B<smtpagent()>>

C<smtpagent()> returns MTA name.

    print Sisimai::MTA::McAfee->smtpagent;

=head2 C<B<scan( I<header data>, I<reference to body string>)>>

C<scan()> method parses a bounced email and return results as a array reference.
See Sisimai::Message for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014 azumakuniyuki E<lt>perl.org@azumakuniyuki.orgE<gt>,
All Rights Reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

