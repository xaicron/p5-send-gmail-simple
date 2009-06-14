use strict;
use warnings;
use Test::Base;
use Test::Exception;

use Send::Gmail::Simple;

plan tests => (1 * blocks);

my $gmail = Send::Gmail::Simple->new('test@example.com', 'password');

filters {
	args => [qw/yaml/],
};

run {
	my $block = shift;
	dies_ok { $gmail->send($block->input) };
};

__END__
=== test nothing
--- args


=== test From only
--- args
From: 'test@example.com'

=== test From TO
--- args
From: 'test@example.com'
TO: 'to@example.com'

=== test From TO Subject
--- args
From: 'test@example.com'
TO: 'to@exmaple.com'
Subject: 'this is test'

=== test Parts undef
--- args
From: 'test@example.com'
TO: 'to@exmaple.com'
Subject: 'this is test'
Body: 'aaa'
Parts:
  Name: 'hoge.jpg'

=== test Parts
--- args
From: 'test@example.com'
TO: 'to@exmaple.com'
Subject: 'this is test'
Body: 'aaa'
Parts:
  Path: 'nothing'
