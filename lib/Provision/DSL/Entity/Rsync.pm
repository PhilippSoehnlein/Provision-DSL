package Provision::DSL::Entity::Rsync;
use Moo;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity';

has path => (
    is => 'lazy',
    # isa => 'PathClassDir',
    # coerce => 1,
    # required => 1,
    # lazy_build => 1,
);
sub _build_path { $_[0]->name }

has content => (
    is => 'ro',
    # isa => 'ExistingDir',
    # coerce => 1,
    # required => 1,
);

has exclude => (
    is => 'ro',
    # isa => 'DirList',
    # coerce => 1,
    # default => sub { [] },
);

sub state {
    my $self = shift;
    
    return 'missing ' if !-d $self->path;
    
    return $self->_rsync_command(
                '--dry-run',
                '--out-format' => 'copying %n',
           ) =~ m{^(?:deleting|copying)\s}xms
        ? 'outdated'
        : 'current';
}

sub _rsync_command {
    my $self = shift;

    my @args = (
        '--verbose',
        '--checksum',
        '--recursive',
        '--delete',
        @_,
        $self->_exclude_list,
        "${\$self->content}/" => "${\$self->path}/",
    );

    return $self->system_command('/usr/bin/rsync', @args);
}

# rsync reports to delete a directory if its subdirectory is in exclusion
# OLD: thus, we have to resolve every path to every of its parents
# NEW: use paths like /dir/ to ensure rsync does a good job
sub _exclude_list {
    my $self = shift;

    my @exclude_list;
    foreach my $path (@{$self->exclude}) {
        $path =~ s{\A / | / \z}{}xmsg;
        push @exclude_list, '--exclude', "/$path";
    }

    return @exclude_list;
}

after ['create', 'change'] => sub { $_[0]->_rsync_command };

1;
