package AndroidRank;

use Mojo::Base -base;

use strict;
use warnings FATAL => 'all';

use Mojo::Util qw/html_unescape/;
use Mojo::DOM;
use Mojo::UserAgent;
use JSON;

use Time::HiRes;

#@returns Mojo::UserAgent
has client => sub {return Mojo::UserAgent->new;};

#@returns JSON
has decoder => sub {return JSON->new->allow_nonref;};

has base_headers => sub {
		return {
			'X-Requested-With' => 'XMLHttpRequest',
			'X-Compress'       => 'null',
			'Referer'          => 'http://www.androidrank.org/',
			'User-Agent'       =>
			'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.119 Safari/537.36',
			'Accept'           =>
			'text/javascript, application/javascript, application/ecmascript, application/x-ecmascript, */*; q=0.01',
			'Accept-Language'  => 'en-US,en;q=0.5',
		};
	};

has suggest_query => '';

has app_details_response => undef;

has app_details_dom => undef;

has app_details_ext_id => '';

has app_details_artist => 'undefined';

has base_suggest_url => 'http://www.androidrank.org/searchjson';

has base_suggest_params => sub {
		my ($timestamp, $microseconds) = Time::HiRes::gettimeofday();

		return {
			callback     => 'Mojo',
			featureClass => 'P',
			style        => 'full',
			_            => sprintf("%10d%03d", $timestamp, substr($microseconds, 0, 3))
		};
	};

sub suggest_params {
	my ($self) = @_;

	my $params = $self->base_suggest_params();
	$params->{name_startsWith} = $self->suggest_query();

	return $params;
};

has base_app_details_url => 'http://www.androidrank.org/application/%s/%s';

has base_app_details_params => sub {
		return {
			hl => 'en'
		}
	};

#@returns Mojo::Message::Response
sub request_suggest {
	my ($self) = @_;

	return unless ($self->suggest_query());

	#@type Mojo::Transaction::HTTP
	my $response;
	my $result;

	eval {
		$response = $self->client->get(
			$self->base_suggest_url() => $self->base_headers()
									  =>
			form                      => $self->suggest_params()
		);
	};

	$result = $response->result()
		if (ref($response) eq 'Mojo::Transaction::HTTP');

	return $result;
};

# suggest(q => ‘uber’)
sub suggest {
	my $self = shift();
	my %args = @_;

	my $output = [];

	return $output if (!defined($args{q}) || !length($args{q}));

	$self->suggest_query($args{q});

	my $result = $self->request_suggest();

	if (
		ref($result) eq 'Mojo::Message::Response'
			&& $result->code == 200
			&& $result->body_size
	) {
		if ($result->body =~ '^Mojo\((.*)\);$') {
			my $json_body = $1;
			my $json;

			eval {$json = $self->decoder->decode($json_body);};

			if (!$@ && $json && ref($json->{geonames}) eq 'ARRAY') {
				foreach my $item (@{$json->{geonames}}) {
					if (ref($item) eq 'HASH') {
						if (exists($item->{appid}) && exists($item->{name})) {
							push(
								@{$output},
								{
									ext_id => $item->{appid},
									title  => $item->{name}
								}
							);
						}
					}
				}
			}
		}
	}

	return $output;
}

#@returns Mojo::Message::Response
sub request_app_details {
	my ($self) = @_;

	return unless ($self->app_details_ext_id());

	my $url = $self->get_app_details_url();

	return unless (defined($url));

	#@type Mojo::Transaction::HTTP
	my $response;
	#@type Mojo::Message::Response
	my $result;

	eval {
		$self->client()->max_redirects(1);
		$response = $self->client->get(
			$url => $self->base_headers()
				 =>
			form => $self->base_app_details_params()
		);
	};

	$result = $response->result()
		if (ref($response) eq 'Mojo::Transaction::HTTP');

	return $result;
};

sub get_app_details_url {
	my ($self) = @_;

	my $artist = $self->app_details_artist();
	my $ext_id = $self->app_details_ext_id();

	return unless ($ext_id);

	my $url = sprintf($self->base_app_details_url(), $artist, $ext_id);

	return $url;
};

# get_app_details(ext_id => ‘com.ubercab’[, artist => 'uber'])
sub get_app_details {
	my $self = shift();
	my %args = @_;

	my $output = {};

	return $output if (!defined($args{ext_id}) || !length($args{ext_id}));

	$self->app_details_ext_id($args{ext_id});
	$self->app_details_artist($args{artist}) if (defined($args{artist}));

	my $result = $self->request_app_details;
	$self->app_details_response($result)
		if ($result);
	$self->app_details_dom($result->dom)
		if ($result);

	$output->{title} = $self->app_details_title // 'NoName';
	$output->{icon} = $self->app_details_icon // '';
	$output->{artist_id} = $self->app_details_artist_id // 0;
	$output->{artist_name} = $self->app_details_artist_name // 'NoName';
	$output->{short_text} = $self->app_details_short_text // '';

	$output->{app_info} = $self->app_details_app_info // {};
	$output->{app_installs} = $self->app_details_app_installs // {};
	$output->{rating_values} = $self->app_details_rating_values // {};
	$output->{rating_score} = $self->app_details_rating_score // {};
	$output->{country_rankings} = $self->app_details_country_rankings // {};

	return $output;

}

sub app_details_title {
	my ($self) = @_;

	my $result;

	eval {
		my $dom = $self->app_details_dom();

		$result = $dom->at('div#content > div[itemscope] > div:nth-child(1) > div:nth-child(1) > div:nth-child(2) > h1 > span[itemprop="name"]')->text
			if (ref($dom) eq 'Mojo::DOM');
	};

	return $result;
}

sub app_details_icon {
	my ($self) = @_;

	my $result;

	eval {
		my $dom = $self->app_details_dom();

		$result = $dom->at('div#content > div[itemscope] > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > a[itemprop="url"] > img[itemprop="image"]')->attr->{src}
			if (ref($dom) eq 'Mojo::DOM');
	};

	return $result;
}

sub app_details_artist_id {
	my ($self) = @_;

	my $result;

	eval {
		my $dom = $self->app_details_dom();

		if (ref($dom) eq 'Mojo::DOM') {
			my $source = $dom->at('div#content > div[itemscope] > div:nth-child(1) > div:nth-child(1) > div:nth-child(2) > small > a')->attr->{href};
			$source =~ /\Sid=(.+)\&/m;
			$result = $1;
		}
	};

	return $result;
}

sub app_details_artist_name {
	my ($self) = @_;

	my $result;

	eval {
		my $dom = $self->app_details_dom();

		$result = $dom->at('div#content > div[itemscope] > div:nth-child(1) > div:nth-child(1) > div:nth-child(2) > small > a')->text
			if (ref($dom) eq 'Mojo::DOM');
	};

	return $result;
}

sub app_details_short_text {
	my ($self) = @_;

	my $result;

	eval {
		my $dom = $self->app_details_dom();

		if (ref($dom) eq 'Mojo::DOM') {
			my $source = $dom->at('div#content > div[itemscope] > div:nth-child(2) > p')->to_string;
			$source =~ s/<[^>]*>//g;
			$source =~ s/^\s+//;
			$source =~ s/\s+Last update on 2018\-01\-21.\s+$//;
			$source = html_unescape($source);
			$result = $source;
		}
	};

	return $result;
}

sub app_details_app_info {
	my ($self) = @_;

	my $result;

	eval {
		my $dom = $self->app_details_dom();

		if (ref($dom) eq 'Mojo::DOM') {
			#@type Mojo::Collection
			my $source = $dom->find('div#content > div[itemscope] > div:nth-child(3) > div:nth-child(1) > table.appstat:nth-child(1) > tbody > tr');
			for my Mojo::DOM $tr ($source->each()) {
				my $key = $self->prepare_key($tr->children('th')->first()->text);
				my $value = $self->prepare_value($tr->children('td')->first()->to_string);

				$result->{$key} = $value
			}
		}
	};

	return $result;
}

sub app_details_app_installs {
	my ($self) = @_;

	my $result;

	eval {
		my $dom = $self->app_details_dom();

		if (ref($dom) eq 'Mojo::DOM') {
			#@type Mojo::Collection
			my $source = $dom->find('div#content > div[itemscope] > div:nth-child(3) > div:nth-child(2) > table.appstat:nth-child(1) > tbody');

			# Bad html markup
			# <tr>
			#   <th>Installs (achieved):</th>
			#   <td>100,000,000+</td>
			# </tr>
			#   <th>Installs (estimated):</th>
			#   <td>500,000,000</td>
			# </tr>
			# </tr>

			#@type Mojo::Collection
			my $tags_list = $source->first->child_nodes;
			my $list = [];

			for my Mojo::DOM $tag ($tags_list->each()) {
				if ($tag->tag()) {
					if ($tag->tag() eq 'tr') {
						my Mojo::Collection $item_list = $tag->child_nodes;

						for my Mojo::DOM $item ($item_list->each) {
							if ($item->tag()) {
								if ($item->tag() eq 'th' || $item->tag() eq 'td') {
									push(@{$list}, $self->app_details_app_install_prepare($item));
								}
							}
						}
					}
					push(@{$list}, $self->app_details_app_install_prepare($tag))
						if ($tag->tag() eq 'th' || $tag->tag() eq 'td');

				}
			}
			%{$result} = @{$list};
		}
	};

	return $result;
}

sub app_details_app_install_prepare {
	my ($self, $tag) = @_;

	my $value = '';

	eval {
		$value = $tag->text;

		$value = $self->prepare_key($value) if ($tag->tag() eq 'th');
		$value = $self->prepare_value($value) if ($tag->tag() eq 'td');
	};

	return $value;
}

sub app_details_rating_values {
	my ($self) = @_;

	my $result;

	eval {
		my $dom = $self->app_details_dom();

		if (ref($dom) eq 'Mojo::DOM') {
			#@type Mojo::Collection
			my $source = $dom->find('div#content > div[itemscope] > div:nth-child(3) > div:nth-child(2) > table.appstat:nth-child(2) > tbody > tr');
			for my Mojo::DOM $tr ($source->each()) {
				my $key = $self->prepare_key($tr->children('th')->first()->text);
				my $value = $self->prepare_value($tr->children('td')->first()->to_string);

				$result->{$key} = $value
			}
		}
	};

	return $result;
}

sub app_details_rating_score {
	my ($self) = @_;

	my $result;

	eval {
		my $dom = $self->app_details_dom();

		if (ref($dom) eq 'Mojo::DOM') {
			#@type Mojo::Collection
			my $source = $dom->find('div#content > div[itemscope] > div:nth-child(3) > div:nth-child(1) > table.appstat:nth-child(2) > tbody > tr');
			for my Mojo::DOM $tr ($source->each()) {
				my $key = $self->prepare_key($tr->children('th')->first()->text);
				my $value = $self->prepare_value($tr->children('td')->first()->to_string);

				$result->{$key} = $value
			}
		}
	};

	return $result;
}

sub app_details_country_rankings {
	my ($self) = @_;

	my $result;

	eval {
		my $dom = $self->app_details_dom();

		if (ref($dom) eq 'Mojo::DOM') {
			#@type Mojo::Collection
			my $source = $dom->find('div#content > div[itemscope] > div:nth-child(5) > span > img');
			for my Mojo::DOM $img ($source->each()) {
				my $key = $self->prepare_key($img->attr->{alt});
				my $value = int($self->prepare_value($img->parent()->text));

				$result->{$key} = $value
			}
		}
	};

	return $result;
}

sub prepare_key {
	my (undef, $value) = @_;

	$value = lc($value);
	$value =~ s/:\s*$//;
	$value =~ s/\W/_/g;
	$value =~ s/__/_/g;
	$value =~ s/_$//g;
	$value =~ s/^_//g;

	return $value;
}

sub prepare_value {
	my (undef, $value) = @_;

	$value =~ s/<[^>]*>//g;
	$value = html_unescape($value);

	return $value;
}

1;