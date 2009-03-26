use strict;
use warnings;
use Test::More tests => 3;
use Test::Exception;

use Send::Gmail::Simple;

dies_ok { Send::Gmail::Simple->new() } 'new no arg';
dies_ok { Send::Gmail::Simple->new('test') } 'new one arg';

my $gmail = Send::Gmail::Simple->new('test@example.com', 'password');

isa_ok($gmail, 'Send::Gmail::Simple');
