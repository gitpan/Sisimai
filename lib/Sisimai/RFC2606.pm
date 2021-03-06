package Sisimai::RFC2606;
use strict;
use warnings;

sub is_reserved {
    # @Description  Whether domain part is Reserved or not
    # @Param <str>  (String) Domain part
    # @Return       (Integer) 1 = is Reserved TLD
    #               (Integer) 0 = is not
    # @See Also     http://www.ietf.org/rfc/rfc2606.txt
    my $class = shift;
    my $dpart = shift || return 0;

    return 1 if $dpart =~ m/[.](?:test|example|invalid|localhost)\z/;
    return 1 if $dpart =~ m/example[.](?:com|net|org)\z/;
    return 1 if $dpart =~ m/example[.]jp\z/;
    return 1 if $dpart =~ m/example[.](?:ac|ad|co|ed|go|gr|lg|ne|or)[.]jp\z/;
    return 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::RFC2606 - Check the email address is reserved or not

=head1 SYNOPSIS

    use Sisimai::RFC2606;
    print Sisimai::RFC2606->is_reserved('example.com');    # 1

=head1 DESCRIPTION

Sisimai::RFC2606 checks that the domain part of the email address in the 
argument is reserved or not.

=head1 CLASS METHODS

=head2 C<B<is_reserved( I<Domain Part> )>>

C<is_reserved()> returns 1 if the domain part is reserved domain, returns 0 if
the domain part is NOT reserved domain.

    print Sisimai::RFC2606->is_reserved('example.org');    # 1
    print Sisimai::RFC2606->is_reserved('bouncehammer.jp');# 0

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014 azumakuniyuki E<lt>perl.org@azumakuniyuki.orgE<gt>,
All Rights Reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut
