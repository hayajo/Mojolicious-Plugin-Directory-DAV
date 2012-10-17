use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

plugin 'Directory::DAV';

use Test::More tests => 2;
use Test::Mojo;

my $resource = 't/upload.txt';
my $t = Test::Mojo->new();
$t->put_ok( "/$resource" => { DNT => 1 } => 'Hello World' )->status_is(201);

unlink $resource;
