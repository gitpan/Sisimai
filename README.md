# NAME

Sisimai - It's a core module of bounceHammer version 4

# SYNOPSIS

    use Sisimai;

# DESCRIPTION

Sisimai is a core module of bounceHammer version. 3, is a Perl module for 
analyzing email bounce. "Sisimai" stands for SISI "Mail Analyzing Interface".

# BASIC USAGE

`make` method provides feature for getting parsed data from bounced email 
messages like following.

    use Sisimai;
    my $v = Sisimai->make( '/path/to/mbox' );   # or Path to Maildir

    if( defined $v ) {
        for my $e ( @$v ) {
            print ref $e;                   # Sisimai::Data
            print $e->recipient->address;   # kijitora@example.jp
            print $e->reason;               # userunknown

            my $h = $e->damn;               # Convert to HASH reference
            my $j = $e->dump('json');       # Convert to JSON string
        }
    }

# SEE ALSO

[Sisimai::Mail](http://search.cpan.org/perldoc?Sisimai::Mail) - Mailbox or Maildir object
[Sisimai::Data](http://search.cpan.org/perldoc?Sisimai::Data) - Parsed data object

# AUTHOR

azumakuniyuki

# COPYRIGHT

Copyright (C) 2014 azumakuniyuki <perl.org@azumakuniyuki.org>,
All Rights Reserved.

# LICENSE

This software is distributed under The BSD 2-Clause License.
