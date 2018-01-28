package AppFollowTest;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    # Load configuration from hash returned by "my_app.conf"
    my $config = $self->plugin('Config');

    # Documentation browser under "/perldoc"
    $self->plugin('PODRenderer') if $config->{perldoc};

    # Router
    my $r = $self->routes;

    # Normal route to controller
    $r->get('/')->to('androidrank#index');

    $r->get('/suggest')->to('androidrank#suggest');
    $r->get('/app_details/')->to('androidrank#app_details');
}

1;
