package Text::Info::BASE;
use Moose;
use namespace::autoclean;

with 'Text::Info::Utils';

use Module::Load;
use Unicode::Normalize;

has 'text' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'tld' => (
    isa     => 'Maybe[Str]',
    is      => 'rw',
    default => '',
);

has 'language' => (
    isa     => 'Str',
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my @lang = $self->CLD->identify( $self->text, tld => $self->tld );
        my $lang = $lang[1];

        if ( $lang eq 'nb' || $lang eq 'nn' ) {
            $lang = 'no';
        }

        return $lang;
    },
);

around 'BUILDARGS' => sub {
    my $orig = shift;
    my $self = shift;

    if ( @_ == 1 && !ref $_[0] ) {
        return $self->$orig( text => $_[0] );
    }
    else {
        return $self->$orig( @_ );
    }
};

has 'words' => ( isa => 'ArrayRef[Str]', is => 'ro', lazy_build => 1 );

sub _build_words {
    my $self = shift;

    return $self->text2words( $self->text );
}

=item word_count

=cut

has 'word_count' => ( isa => 'Int', is => 'ro', lazy_build => 1 );

sub _build_word_count {
    my $self = shift;

    return scalar( @{$self->words} );
}

=item syllable_count

=cut

has 'syllable_count' => ( isa => 'Int', is => 'ro', lazy_build => 1 );

sub _build_syllable_count {
    my $self = shift;

    my $class_name = 'Lingua::' . uc( $self->language ) . '::Syllable';
    autoload $class_name;

    my $count = 0;

    foreach my $word ( @{$self->words} ) {
        $count += syllable( Unicode::Normalize::NFD($word) );
    }

    return $count;
}

=item ngrams( $size )

=cut

sub ngrams {
    my $self = shift;
    my $size = shift || 2;

    my @ngrams = ();
    my @words  = @{ $self->words };

    for ( my $word_idx = 0; $word_idx < @words; $word_idx++ ) {
        my @w = @words[ $word_idx .. $word_idx + ($size - 1) ];
        if ( defined $w[-1] ) {
            push( @ngrams, join(' ', @w) );
        }
    }

    return \@ngrams;
}

=item unigrams

=cut

has 'unigrams' => ( isa => 'ArrayRef[Str]', is => 'ro', lazy_build => 1 );

sub _build_unigrams {
    my $self = shift;

    return $self->ngrams( 1 );
}

=item bigrams

=cut

has 'bigrams' => ( isa => 'ArrayRef[Str]', is => 'ro', lazy_build => 1 );

sub _build_bigrams {
    my $self = shift;

    return $self->ngrams( 2 );
}

=item trigrams

=cut

has 'trigrams' => ( isa => 'ArrayRef[Str]', is => 'ro', lazy_build => 1 );

sub _build_trigrams {
    my $self = shift;

    return $self->ngrams( 3 );
}

=item quadgrams

=cut

has 'quadgrams' => ( isa => 'ArrayRef[Str]', is => 'ro', lazy_build => 1 );

sub _build_quadgrams {
    my $self = shift;

    return $self->ngrams( 4 );
}

__PACKAGE__->meta->make_immutable;

1;
