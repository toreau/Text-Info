package Text::Info;
use Moose;
use namespace::autoclean;

use Text::Info::Sentence;

extends 'Text::Info::BASE';

our $VERSION = '0.01';

# has 'text' => ( isa => 'Str', is => 'rw', default => '' );
# has 'tld'  => ( isa => 'Str', is => 'rw', default => '' );

=head1 METHODS

=over

=item new()

Returns a new Text::Info object. Can take text as a single argument, or text
and tld (top level domain, for better language detection):

    my $text = Novus::Text->new( 'Dette er en norsk tekst.' );

    # ...or...

    my $text = Novus::Text->new(
        text => 'Dette er en norsk tekst.',
        tld  => 'no',
    );

=cut

# around 'BUILDARGS' => sub {
#     my $orig = shift;
#     my $self = shift;

#     if ( @_ == 1 && !ref $_[0] ) {
#         return $self->$orig( text => $_[0] );
#     }
#     else {
#         return $self->$orig( @_ );
#     }
# };

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

=item ngrams( $size )

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

=item word_count

=cut

has 'word_count' => ( isa => 'Int', is => 'ro', lazy_build => 1 );

sub _build_word_count {
    my $self = shift;

    return scalar( @{$self->words} );
}

=item avg_word_length

=cut

has 'avg_word_length' => ( isa => 'Num', is => 'ro', lazy_build => 1 );

sub _build_avg_word_length {
    my $self = shift;

    my $total_length = 0;

    foreach my $word ( @{$self->words} ) {
        $total_length += length( $word );
    }

    return $total_length / $self->word_count;
}

=item sentence_count

=cut

has 'sentence_count' => ( isa => 'Int', is => 'ro', lazy_build => 1 );

sub _build_sentence_count {
    my $self = shift;

    return scalar( @{$self->sentences} );
}

=item avg_sentence_length

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

=item fres

=cut

has 'fres' => ( isa => 'Num', is => 'ro', lazy_build => 1 );

sub _build_fres {
    my $self = shift;

    # my $total_words     = $self->word_count;
    # my $total_sentences = scalar( @{$self->sentences} );
    # my $total_syllables = $self->syllable_count;

    my $words_per_sentence = $self->word_count / $self->sentence_count;
    my $syllables_per_word = $self->syllable_count / $self->word_count;

    my $readability = 206.835 - ( ($words_per_sentence * 1.015) + ($syllables_per_word * 84.6) );

    return sprintf( '%.2f', $readability );
}

__PACKAGE__->meta->make_immutable;

1;

=back
