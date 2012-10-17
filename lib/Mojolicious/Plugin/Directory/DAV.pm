package Mojolicious::Plugin::Directory::DAV;
use strict;
use warnings;
our $VERSION = '0.01';

use Mojo::Base qw{ Mojolicious::Plugin::Directory };
use Carp ();
use Cwd ();
use Filesys::Virtual::Plain;
use HTTP::Request;
use MIME::Base64 ();
use Mojo::Loader;
use Net::DAV::Server;

sub register {
    my $self = shift;
    my ( $app, $args ) = @_;

    $args->{root} ||= Cwd::getcwd;
    Carp::croak sprintf( 'root "%s" is not a directory', $args->{root} )
        unless -d $args->{root};
    my $dav = Net::DAV::Server->new(
        -filesys => Filesys::Virtual::Plain->new( { root_path => $args->{root} } ),
        -dbobj   => $self->_dbobj( $args->{dbobj} ),
    );

    $args->{handler} = sub {
        my ( $c, $path ) = @_;
        return if ( $c->req->method eq 'GET' );
        $c->req->headers->authorization( $self->_basic_auth() )
            unless ( $c->req->headers->authorization );
        my $req = $self->_http_request( $c->req );
        my $res = $dav->run($req);
        $self->_render_http_response( $c, $res );
    };

    return $self->SUPER::register($app, $args);
}

sub _dbobj {
    my $class = shift;
    my $args  = shift;
    my ( $classname, $db_args ) = ( ref $args )
        ? @{ $args }
        : $args || 'Simple';
    my $db_class = 'Net::DAV::LockManager::' . $classname;
    my $db_path  = Mojo::Util::class_to_path($db_class);
    require $db_path; # no critic
    return ($db_args) ? $db_class->new($db_args) : $db_class->new();
}

sub _basic_auth {
    my $class    = shift;
    my $user     = shift || getpwuid($>);
    my $password = shift || '';
    return 'Basic ' . MIME::Base64::encode("$user:$password");
}

sub _http_request {
    my $class = shift;
    my $req   = shift or return HTTP::Request->new;
    return HTTP::Request->new(
        $req->method,
        $req->url->to_string,
        [ %{ $req->headers->to_hash } ],
        $req->body,
    );
}

sub _render_http_response {
    my $class = shift;
    my ( $c, $http_res ) = @_;
    for my $key ( $http_res->headers->header_field_names ) {
        $c->res->headers->header( $key => $http_res->headers->header($key) );
    }
    $c->render_data( $http_res->content );
    $c->rendered( $http_res->code );
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::Directory::DAV - Simple DAV server for Mojolicious

=head1 SYNOPSIS

  use Mojolicious::Lite;
  plugin( 'Directory::DAV', root => "/path/to/htdocs" )->start;

  or

  > perl -Mojo -E 'a->plugin("Directory::DAV", root => "/path/to/htdocs")->start' daemon

=head1 DESCRIPTION

Mojolicious::Plugin::Directory::DAV is Simple DAV server for Mojolicious.

inspired by L<Plack::App::Direcotry>.

=head1 METHODS

L<Mojolicious::Plugin::Directory::DAV> inherits all methods from L<Mojolicious::Plugin::Directory>.

=head1 OPTIONS

Mojolicious::Plugin::Directory::DAV supports the following options.

=head2 C<root>

  # Mojolicious::Lite
  plugin "Directory::DAV" => { root => "/path/to/htdocs" };

Document root directory. Defaults to the current directory.

=head2 C<dbobj>

same as L<Plack::App::DAV> CONFIGURATION.

=head1 EXAMPLE

=over 4

=item * with Git

  # in server

  > mkdir myrepo.git && myrepo.git
  > git init --bare
  > git update-server-info
  > perl -Mojo -E 'a->plugin("Directory::DAV")->start' daemon

  # in client

  > git clone http://repo-server.example.net:3000/ myrepo
  > cd myrepo
  > echo 'hello world' > README
  > git add .
  > git commit -m 'initial commit'
  > git push origin master

B<** When using old version of git,  'git pull' command may fail. **>

B<** I have confirmed the success of 'git pull' by git-1.7.3.4 or later. **>

=item * with Mac OSX Finder

After start server, connect with a Guest-User.

B<** Windows "Network Place" unsupported. **>

=item * and more

=back

=head1 AUTHOR

hayajo E<lt>hayajo@cpan.orgE<gt>

=head1 SEE ALSO

L<Plack::App::DAV>, L<Mojolicious::Plugin::Directory>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
