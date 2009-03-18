use inc::Module::Install;
name 'Send-Gmail-Simple';
all_from 'lib/Send/Gmail/Simple.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
