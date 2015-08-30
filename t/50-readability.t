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

is( $text->fres, '34.53', 'FRES value is OK!' );

#
# Norwegian
#
$text = Text::Info->new(
    text => "– Dette er den minst gjennomtenkte valgkampsaken i Norge på mange år. Her hadde Oslo Ap før første gang på mange år en god mulighet til å vinne makten i Oslo. Jeg skjønner ikke hvordan det er mulig å gjøre et så dårlig strategisk valg. De har selv bidratt til at Fabian Stang og Stian Berger Røsland mest sannsynlig får fortsette, sier pr-nestor Hans Geelmuyden, sjef i Geelmuyden Kiese.",
);

is( $text->fres, '47.10', 'FRES value is OK!' );

#
# The End
#
done_testing;
