package Provision::DSL::Entity::Execute;
use Moo;
use Cwd;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity';
with 'Provision::DSL::Role::User',
     'Provision::DSL::Role::Group',
     'Provision::DSL::Role::CommandExecution';

has path => (
    is => 'lazy',
    isa => ExecutableFile,
    coerce => to_File,
);

sub _build_path { $_[0]->name }

has chdir => (
    is => 'ro',
    isa => ExistingDir,
    coerce => to_Dir,
    predicate => 1,
);

has arguments => (
    is => 'ro',
    default => sub { [] },
);

has args => (
    is => 'lazy',
);

sub _build_args { $_[0]->arguments }

has environment => (
    is => 'ro',
    default => sub { {} },
);

has env => (
    is => 'lazy',
);

sub _build_env { $_[0]->environment }

# needed to make Execute work like a resource.
sub content { $_[0]->_execute }

sub _execute {
    my $self = shift;

    my $cwd = getcwd;
    chdir $self->chdir if $self->has_chdir;

    my $script_output = $self->run_command_as_user(
        $self->path->stringify,
        { env => $self->env },
        @{$self->args},
    );

    chdir $cwd if $self->has_chdir;

    return $script_output;
}

after ['create', 'change'] => sub { $_[0]->_execute };

1;
