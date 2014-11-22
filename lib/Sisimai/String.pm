package Sisimai::String;
use feature ':5.10';
use strict;
use warnings;
use Digest::SHA;

sub token {
    # @Description  Create message token from addresser and recipient 
    # @Param        (String) Sender address
    # @Param        (String) Recipient address
    # @Param        (Integer) Machine time of the email bounce
    # @Return       (String) Message token(MD5 hex digest)
    #               (String) Blank/failed to create token
    # @See          http://en.wikipedia.org/wiki/ASCII
    #               http://search.cpan.org/~gaas/Digest-MD5-2.39/MD5.pm
    my $class = shift || return '';
    my $addr1 = shift || return '';
    my $addr2 = shift || return '';
    my $epoch = shift // return '';

    # Format: STX(0x02) Sender-Address RS(0x1e) Recipient-Address ETX(0x03)
    return Digest::SHA::sha1_hex( 
        sprintf( "\x02%s\x1e%s\x1e%d\x03", lc $addr1, lc $addr2, $epoch ) );
}

sub is_8bit {
    # @Description  8bit text or not
    # @Param <ref>  (Ref->Scalar) String
    # @Return       0 = ASCII Characters only
    #               1 = Including 8bit character
    my $class = shift;
    my $argvs = shift // return undef;

    return undef unless ref $argvs;
    return undef unless ref $argvs eq 'SCALAR';
    return 1 unless $$argvs =~ m/\A[\x00-\x7f]+\z/;
    return 0;
}

sub sweep {
    # @Description  Clean the string out
    # @Param <ref>  (Scalar) String
    # @Return       (Scalar) String cleaned out
    my $class = shift;
    my $argvs = shift // return undef;

    chomp $argvs;
    $argvs =~ y{ }{}s;
    $argvs =~ s{\A }{}g;
    $argvs =~ s{ \z}{}g;
    $argvs =~ s{ [-]{2,}.+\z}{};

    return $argvs;
}

1;
__END__
=encoding utf-8

=head1 NAME

Sisimai::String - String related class

=head1 SYNOPSIS

    use Sisimai::String;
    my $s = 'envelope-sender@example.jp';
    my $r = 'envelope-recipient@example.org';
    my $t = time();

    print Sisimai::String->token( $s,$r,$t );  # 2d635de42a44c54b291dda00a93ac27b
    print Sisimai::String->is_8bit( \'猫');    # 1
    print Sisimai::String->sweep(' neko cat ');# 'neko cat'

=head1 DESCRIPTION

Sisimai::String provide utilities for dealing string

=head1 CLASS METHODS

=head2 C<B<token( I<sender>, I<recipient> )>>

C<token()> generates a token: Unique string generated by an envelope sender
address and a envelope recipient address.

    my $s = 'envelope-sender@example.jp';
    my $r = 'envelope-recipient@example.org';

    print Sisimai::String->token( $s, $r );    # 2d635de42a44c54b291dda00a93ac27b

=head2 C<B<is_8bit( I<Reference to String> )>>

C<is_8bit()> checks the argument include any 8bit character or not.

    print Sisimai::String->is_8bit( \'cat' );  # 0;
    print Sisimai::String->is_8bit( \'ねこ' ); # 1;

=head2 C<B<sweep( I<String> )>>

C<sweep()> clean the argument string up: remove trailing spaces, squeeze spaces.

    print Sisimai::String->sweep( ' cat neko ' );  # 'cat neko';
    print Sisimai::String->sweep( ' nyaa   !!' );  # 'nyaa !!';

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014 azumakuniyuki E<lt>perl.org@azumakuniyuki.orgE<gt>,
All Rights Reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut
