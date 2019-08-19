package SL::Controller::Mojolicious;
use Mojo::Base 'Mojolicious::Controller';

sub hello {
    my $self = shift;

    $self->render(sometext => 'This is a minimal Mojolicious-rendered page.');
}


# We could leave that out, since it does nothing more
# than the Mojolicious default:
sub sysinfo {
    my $self = shift;

    $self->render();
}


1;
