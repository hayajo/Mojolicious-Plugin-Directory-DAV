use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

plugin 'Directory::DAV';

use Test::More tests => 4;
use Test::Mojo;

my $resource = 't/upload.txt';

my $t = Test::Mojo->new();
$t->put_ok( "/$resource" => 'Hello World' )->status_is(201);
$t->delete_ok("/$resource")->status_is(204);
