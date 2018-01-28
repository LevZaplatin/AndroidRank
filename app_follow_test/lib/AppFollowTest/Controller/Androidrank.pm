package AppFollowTest::Controller::Androidrank;
use Mojo::Base 'Mojolicious::Controller';

use AndroidRank;

sub index {
	my ($self) = @_;

	$self->render();
}

sub suggest {
	my ($self) = @_;

	my $parser = AndroidRank->new();

	$self->render(
		json => {
			results => $parser->suggest(q => $self->param('query'))
		}
	);
}

sub app_details {
	my ($self) = @_;

	my $parser = AndroidRank->new();

	$self->render(
		json => $parser->get_app_details(
			ext_id => $self->param('ext_id'),
			artist => $self->param('artist')
		)
	);
}

1;