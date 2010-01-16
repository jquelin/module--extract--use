package Local::Inheritance;

# inheritance
use base "Local::Base::base1";
use base qw{ Local::Base::base2 Local::Base::base3 };
use parent "Local::Base::parent1";
use parent qw{ Local::Base::parent2 Local::Base::parent3 };

1;
