package Provision::DSL::Inspector;
use Moo;
use Carp;
use Provision::DSL::Types;

with 'Provision::DSL::Role::Entity';

has attribute => (
    is        => 'lazy',
    predicate => 1,
);

# may get changed in derieved classes if attribute is different
sub _build_attribute { 'name' }

# retrieve actual value from entity's attribute given above
sub value { $_[0]->entity->${\$_[0]->attribute} }

# return actual values as list
sub values {
    map { defined $_ ? $_ : () }
    map { ref $_ eq 'ARRAY' ? @$_ : $_ } $_[0]->value;
}

has expected_value => (
    is        => 'ro',
    predicate => 1,
);

# return expected values as list of defined values
sub expected_values {
    map { defined $_ ? $_ : () }
    map { ref $_ eq 'ARRAY' ? @$_ : $_ } $_[0]->expected_value;
}

has state => (
    is      => 'lazy',
    isa     => State,
    clearer => 1,
);

sub _build_state { croak '_build_state must be defined in implementation' }

has need_privilege => (
    is => 'lazy',
    isa => Bool,
);

sub _build_need_privilege { 0 }

sub is_current  { $_[0]->state eq 'current' }
sub is_missing  { $_[0]->state eq 'missing' }
sub is_outdated { $_[0]->state eq 'outdated' }

1;
