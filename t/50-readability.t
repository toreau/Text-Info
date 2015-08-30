use Test::More;
use utf8;

use Text::Info;

#
# Tested against https://readability-score.com/
#
my $text = Text::Info->new(
    text     => "Rudolph Agnew, 55 years old and former chairman of Consolidated Gold Fields PLC, was named a director of this British industrial conglomerate.",
    language => 'en',
);

is( $text->fres, 34.53, 'FRES value is OK!' );

done_testing;
