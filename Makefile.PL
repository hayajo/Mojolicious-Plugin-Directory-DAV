use inc::Module::Install;
use Module::Install::Repository;
name 'Mojolicious-Plugin-Directory-DAV';
all_from 'lib/Mojolicious/Plugin/Directory/DAV.pm';

requires 'Mojolicious::Plugin::Directory' => '0.05';
requires 'Filesys::Virtual::Plain'        => '0.10';
requires 'HTTP::Message'                  => '6.03';
requires 'Net::DAV::Server'               => '1.304';

tests 't/*.t';

test_requires 'Test::More';
test_requires 'Data::Structure::Util';

auto_set_repository;
auto_include;
WriteAll;
