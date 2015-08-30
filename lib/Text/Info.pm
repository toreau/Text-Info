package Text::Info;
use Moose;
use namespace::autoclean;

use Text::Info::Sentence;

extends 'Text::Info::BASE';

=encoding utf-8

=head1 NAME

Text::Info - Retrieve information about, and do analysis on, text.

=head1 VERSION

Version 0.01.

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Text::Info;

    my $text = Text::Info->new( "Some text..." );

    say "The text is written in language '" . $text->language . "',";
    say "and has a readability score (FRES) of " . $text->fres;

=head1 DESCRIPTION

=head1 METHODS

=over

=item new()

Returns a new L<Text::Info> object. Can take the C<text> as a single argument,
optionally C<tld> (top level domain, for better language detection), and/or
optionally C<language> if you want to specify the text's language yourself.

    my $text = Text::Info->new( 'Dette er en norsk tekst.' );

    # ...or...

    my $text = Text::Info->new(
        text => 'Dette er en norsk tekst.',
        tld  => 'no',
    );

    # ...or...

    my $text = Text::Info->new(
        text     => 'Dette er en norsk tekst.'
        language => 'no',
    );

It really doesn't make sense to set both C<tld> and C<language>, as the
former is a helper for detecting the correct language of the text, while
the latter overrides whatever the detection algorithm returns.

=item sentences()

Returns an array reference of the text's sentences as C<Text::Info::Sentence>
objects.

Keep in mind that this method tries to remove any separators, so the sentences
returned should NOT contain those. For example "This is a sentence!" will be
returned as "This is a sentence".

=cut

has 'sentences' => ( isa => 'ArrayRef[Text::Info::Sentence]', is => 'ro', lazy_build => 1 );

sub _build_sentences {
    my $self = shift;

    my $marker = '</marker/>';
    my $text   = $self->text;
    my $separators = '.?!:;';

    # Mark separators with a marker.
    $text =~ s/([\Q$separators\E]+\s*)/$1$marker/sg;

    # Abbreviations.
    foreach ( qw( Prof Ph Dr Mr Mrs Ms Hr St ) ) {
        $text =~ s/($_\.\s+)\Q$marker\E/$1/sg;
    }

    # U.N., U.S.A.
    $text =~ s/([[:upper:]]{1}\.)\Q$marker\E/$1/sg;

    # Clockwork.
    $text =~ s/(kl\.\s+)\Q$marker\E(\d+.)(\d+.)\Q$marker\E(\d+)/$1$2$3$4/sg;
    $text =~ s/(kl\.\s+)\Q$marker\E(\d+.)\Q$marker\E(\d+)/$1$2$3/sg;
    $text =~ s/(\d+.)\Q$marker\E(\d+)/$1$2/sg;
    $text =~ s/(\d+.)\Q$marker\E(\d+.)\Q$marker\E(\d+)/$1$2$3/sg;
    $text =~ s/(\d+\s+[ap]\.)\Q$marker\E(m\.\s*)\Q$marker\E/$1$2/sg;
    $text =~ s/(\d+\s+[ap]m\.\s+)\Q$marker\E/$1/sg;

    # Remove marker if it looks like we're dealing with a date abbrev., like "Nov. 29" etc.
    my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    foreach my $month ( @months ) {
        $text =~ s/($month\.\s+)\Q$marker\E(\d+)/$1$2/sg;
    }

    # Markers immediately followed by a (possible space and) lowercased character should be removed.
    # This is useful for TLDs/domain names like "cnn.com".
    $text =~ s/\Q$marker\E\s*([[:lower:]])/$1/sg;

    # Markers immediately prefixed by a space + single uppercased characters should be removed.
    # This is fine for f.ex. names like "Magne T. Øierud".
    $text =~ s/(\s+[[:upper:]]\.\s+)\Q$marker\E/$1/sg;

    # Build sentences.
    my @sentences = ();

    foreach my $sentence ( split(/\Q$marker\E/, $text) ) {
        1 while ( $sentence =~ s/[\Q$separators\E\s]$// );

        $sentence =  $self->squish( $sentence );
        $sentence =~ s/^\-+\s*//sg;

        if ( length $sentence ) {
            push( @sentences, Text::Info::Sentence->new(text => $sentence, tld => $self->tld) );
        }
    }

    # Return
    return \@sentences;
}

=item sentence_count()

Returns the number of sentences in the text.

=cut

has 'sentence_count' => ( isa => 'Int', is => 'ro', lazy_build => 1 );

sub _build_sentence_count {
    my $self = shift;

    return scalar( @{$self->sentences} );
}

=item avg_sentence_length()

Returns the average length of the sentences in the text.

=cut

has 'avg_sentence_length' => ( isa => 'Num', is => 'ro', lazy_build => 1 );

sub _build_avg_sentence_length {
    my $self = shift;

    my $total_length = 0;

    foreach my $sentence ( @{$self->sentences} ) {
        $total_length += length( $sentence->text );
    }

    return $total_length / $self->sentence_count;
}

=item words()

Returns an array reference containing the text's words. This method is derived
from L<Text::Info::BASE>.

=item word_count()

Returns the number of words in the text. This is a helper method and is derived
from L<Text::Info::BASE>.

=item avg_word_length()

Returns the average length of the words in the text. This is a helper method and
is derived from L<Text::Info::BASE>.

=item ngrams( $size )

Returns an array reference containing the text's ngrams of size C<$size>.
Default size is 2 (i.e. bigrams). This method overrides L<Text::Info::BASE>'s
C<ngrams()> method, as it takes into accounts building ngrams based on the
text's sentences, not the text's complete list of words.

=cut

override 'ngrams' => sub {
    my $self = shift;

    my @ngrams = ();

    foreach my $sentence ( @{$self->sentences} ) {
        foreach my $ngram ( @{$sentence->ngrams(@_)} ) {
            push( @ngrams, $ngram );
        }
    }

    return \@ngrams;
};

=item unigrams()

Returns an array reference containing the text's unigrams, i.e. the same
as C<ngrams(1)>. This is a helper method and is derived from L<Text::Info::BASE>.

=item bigrams()

Returns an array reference containing the text's bigrams, i.e. the same
as C<ngrams(2)>. This is a helper method and is derived from L<Text::Info::BASE>.

=item trigrams()

Returns an array reference containing the text's trigrams, i.e. the same
as C<ngrams(3)>. This is a helper method and is derived from L<Text::Info::BASE>.

=item quadgrams()

Returns an array reference containing the text's quadgrams, i.e. the same
as C<ngrams(4)>. This is a helper method and is derived from L<Text::Info::BASE>.

=item syllable_count()

Returns the number of syllables in the text. This method requires that
Lingua::__::Syllable is available for the language in question. This method
is derived from L<Text::Info::BASE>.

=item fres()

Returns the text's "Flesch reading ease score" (FRES), a text readability score.
See L<Flesch–Kincaid readability tests|https://en.wikipedia.org/wiki/Flesch%E2%80%93Kincaid_readability_tests> on Wikipedia for more information.

Returns undef is it's impossible to calculate the score, for example if the
there is no text, no sentences that could be detected etc.

=cut

has 'fres' => ( isa => 'Maybe[Num]', is => 'ro', lazy_build => 1 );

sub _build_fres {
    my $self = shift;

    return undef if ( $self->text           eq '' );
    return undef if ( $self->sentence_count == 0  );
    return undef if ( $self->word_count     == 0  );

    my $words_per_sentence = $self->word_count / $self->sentence_count;
    my $syllables_per_word = $self->syllable_count / $self->word_count;

    my $score = 206.835 - ( ($words_per_sentence * 1.015) + ($syllables_per_word * 84.6) );

    return sprintf( '%.2f', $score );
}

=item fkrgl()

Returns the text's "Flesch–Kincaid reading grade level", a text readability score.
See L<Flesch–Kincaid readability tests|https://en.wikipedia.org/wiki/Flesch%E2%80%93Kincaid_readability_tests> on Wikipedia for more information.

Returns undef is it's impossible to calculate the score, for example if the
there is no text, no sentences that could be detected etc.

=cut

has 'fkrgl' => ( isa => 'Maybe[Num]', is => 'ro', lazy_build => 1 );

sub _build_fkrgl {
    my $self = shift;

    return undef if ( $self->text           eq '' );
    return undef if ( $self->sentence_count == 0  );
    return undef if ( $self->word_count     == 0  );

    my $words_per_sentence = $self->word_count / $self->sentence_count;
    my $syllables_per_word = $self->syllable_count / $self->word_count;

    my $score = ( ($words_per_sentence * 0.39) + ($syllables_per_word * 11.8) ) - 15.59;

    return sprintf( '%.2f', $score );
}

__PACKAGE__->meta->make_immutable;

1;

=back

=head1 SEE ALSO

=over 4

=item * L<Text::Info::Sentence>

=back

=head1 AUTHOR

Tore Aursand, C<< <toreau at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to the web interface at L<https://rt.cpan.org/Dist/Display.html?Name=Text-Info>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Info

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Info>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Info>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Info/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Tore Aursand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
