package Provision::DSL::Entity::Dir;
use Moo;
use Provision::DSL::Types;
# use Provision::DSL::Util 'remove_recursive';

sub path;    # must forward-declare

extends 'Provision::DSL::Entity::Compound';
with    'Provision::DSL::Role::CommandExecution',
        'Provision::DSL::Role::User',
        'Provision::DSL::Role::Group',
        'Provision::DSL::Role::PathPermission',
        'Provision::DSL::Role::PathOwner';

sub _build_permission { '0755' }

has path => (
    is     => 'lazy',
    coerce => to_Dir,
);
sub _build_path { $_[0]->name }

has mkdir => (
    is      => 'rw',
    default => sub { [] },
);

has rmdir => (
    is      => 'rw',
    default => sub { [] },
);

has content => (
    is        => 'ro',
    coerce    => to_ExistingDir,
    predicate => 'has_content',
);

before state => sub {
    $_[0]->set_state(-d $_[0]->path ? 'current' : 'missing')
};

before create => sub {
    my $self = shift;
    
    $self->run_command_as_user(
        '/bin/mkdir',
        '-p', $self->path,
    );
};

after remove => sub {
    my $self = shift;

    $self->run_command_as_user(
        '/bin/rm',
        '-rf', $self->path,
    );
};

sub _build_children {
    my $self = shift;

    return [
        $self->__as_entities( $self->mkdir, 1 ),
        $self->__as_entities( $self->rmdir, 0 ),

        (
            $self->has_content
            ? $self->create_entity(
                Rsync => {
                    parent  => $self,
                    name    => $self->name,
                    path    => $self->path,
                    content => $self->content,
                    exclude => $self->mkdir,
                }
              )
            : ()
        ),
    ];
}

sub __as_entities {
    my ( $self, $directories, $wanted ) = @_;

    map {
        $self->create_entity(
            Dir => {
                parent => $self,
                name   => $_,
                path   => $self->path->subdir($_),
                wanted => $wanted,
            }
          )
      }
      @$directories;
}

1;
