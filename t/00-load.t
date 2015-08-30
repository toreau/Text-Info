use Test::More;

BEGIN {
    use_ok( 'Text::Info'           );
    use_ok( 'Text::Info::Sentence' );
    use_ok( 'Text::Info::Utils'    );
}

diag( 'Testing Text::Info ' . $Text::Info::VERSION );

done_testing;
