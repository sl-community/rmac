package SL::Helper::Basic;
use base 'Mojolicious::Plugin';
use strict;
use warnings;
use v5.10;

use lib ("mojo/lib");
use SL::Model::Config;


sub register {

    my ($self, $app) = @_;

    $app->helper(
        userconfig => sub {
            my $self = shift;

            my $conf  = SL::Model::Config->instance($self);

            return $conf;
        }
    );

    $app->helper(
        # We have to implement our own cookie parser, because SL uses
        # cookie names like "SL-root login", which is not RFC 6265
        # compatible, and Mojolicious parses them wrong :-(
        
        # https://www.perlmonks.org/bare/?node_id=99379
        cookies => sub {
            my $self = shift;

            my $cookie_raw = $self->req->headers->cookie;

            my %decode = ('\+'=>' ','\%3A\%3A'=>'::','\%26'=>'&','\%3D'=>'=',
                          '\%2C'=>',','\%3B'=>';','\%2B'=>'+','\%25'=>'%');

            my %cookies = ();
            foreach (split(/; /, $cookie_raw)) {
                my ($cookie, $value) = split(/=/);
                foreach my $ch ('\+','\%3A\%3A','\%26','\%3D','\%2C','\%3B','\%2B','\%25') {
                    $cookie =~ s/$ch/$decode{$ch}/g;
                    $value =~ s/$ch/$decode{$ch}/g;
                }
                $cookies{$cookie} = $value;
            }
            return \%cookies;
        }
    );

    
}

1;
