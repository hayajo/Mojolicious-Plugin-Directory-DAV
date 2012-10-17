use strict;
use Test::More tests => 3;

use Mojolicious::Plugin::Directory::DAV;
use Data::Structure::Util qw{ unbless };
use MIME::Base64;
use Mojo::Message::Request;

my $class  = 'Mojolicious::Plugin::Directory::DAV';

subtest '_dbobj' => sub {
    subtest 'no args' => sub {
        my $dbobj = $class->_dbobj();
        isa_ok $dbobj, 'Net::DAV::LockManager::Simple';
        unbless($dbobj);
        is_deeply $dbobj, [];
    };
    my $lockdb = 't/lockdb.sqlite3';
    my @args = (
        [ 'Simple' ],
        [ 'DB' ],
        [ 'DB', 'dbi:SQLite::memory:' ],
        [ 'DB', "dbi:SQLite:$lockdb" ],
    );
    for my $arg (@args) {
        my $dbobj = $class->_dbobj($arg);
        isa_ok $dbobj, 'Net::DAV::LockManager::' . $arg->[0];
    }
    unlink $lockdb;
};

subtest '_basic_auth' => sub {
    my @args = (
        [],
        [ 'user', 'password' ],
    );
    for my $arg (@args) {
        my $auth_basic = $class->_basic_auth(@$arg);
        my (undef, $encoded) = split / /, $auth_basic, 2;
        my ($user, $password) = split /:/, MIME::Base64::decode($encoded);
        is $user, $arg->[0] // getpwuid($>);
        is $password, $arg->[1] // '';
    }
    ok 1;
};

subtest '_http_request' => sub {
    my $req = Mojo::Message::Request->new;
    $req->parse("GET / HTTP/1.0\x0d\x0a");
    $req->parse("Additional-Header: value\x0d\x0a");
    $req->parse("Content-Length: 12\x0d\x0a");
    $req->parse("Content-Type: text/plain\x0d\x0a\x0d\x0a");
    $req->parse('Hello World');
    my $http_req = $class->_http_request($req);
    is $http_req->method, 'GET';
    is $http_req->uri, '/';
    is $http_req->header('Additional-Header'), 'value';
    is $http_req->header('Content-Length'), 12;
    is $http_req->header('Content-Type'), 'text/plain';
    is $http_req->content, 'Hello World';
};
