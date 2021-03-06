package Provision::DSL::Role::CommandAndArgs;
use Moo::Role;
use Provision::DSL::Types;

has command => (
    is     => 'lazy',
    coerce => to_Str,
);

sub _build_command { $_[0]->name }

has args => (
    is => 'lazy',
);

sub _build_args { [] }

1;
