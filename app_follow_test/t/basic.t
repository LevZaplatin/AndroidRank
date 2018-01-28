use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('AppFollowTest');
$t->get_ok('/')->status_is(200)->content_like(qr/AndroidRank Viewer/i);

$t->get_ok('/suggest/?query=uber')->status_is(200)->json_has("/results/0");
$t->get_ok('/Not-Found-Page/')->status_is(404);

$t->get_ok('/suggest/?query=uber')->status_is(200)->json_is("/results/0/title", "Uber");
$t->get_ok('/suggest/?query=uber')->status_is(200)->json_is("/results/0/ext_id", "com.ubercab");

$t->get_ok('/suggest/?query=telegram')->status_is(200)->json_is("/results/0/title", "Telegram");
$t->get_ok('/suggest/?query=telegram')->status_is(200)->json_is("/results/0/ext_id", "org.telegram.messenger");

$t->get_ok('/app_details/?ext_id=org.telegram.messenger')->status_is(200)->json_is("/artist_id", "Telegram+Messenger+LLP");
$t->get_ok('/app_details/?ext_id=org.telegram.messenger')->status_is(200)->json_is("/artist_name", "Telegram Messenger LLP");

$t->get_ok('/app_details/?ext_id=com.ubercab')->status_is(200)->json_is("/artist_id", "7908612043055486674");
$t->get_ok('/app_details/?ext_id=com.ubercab')->status_is(200)->json_is("/artist_name", "Uber Technologies, Inc.");

done_testing();
