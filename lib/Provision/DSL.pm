package Provision::DSL;
use strict;
use warnings;
use feature ':5.10';
use FindBin;

=head1 NAME

Provision::DSL - a simple provisioning toolkit

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

TODO

=cut

#
# up to this point, nothing bad happens.
# Provision::Prepare will ensure that everything requested to continue
# is there or dies otherwise.
#
# use Provision::DSL::Prepare;

#
# starting here, we are in good shape and can use everything we need.
#
use Path::Class;
use Module::Pluggable search_path => 'Provision::DSL::Entity', sub_name => 'entities';
use Module::Pluggable search_path => 'Provision::DSL::Source', sub_name => 'sources';
use Module::Load;
use Moose;
use Moose::Util::TypeConstraints qw(class_type coerce
                                    from via
                                    find_type_constraint);

our @EXPORT = qw(Done done OS Os os);

our $app;

sub import {
    my $package = caller;

    warnings->import();
    strict->import();
    feature->import(':5.10');

    $app = _instantiate_app();
    _create_and_export_entity_keywords($package);
    _create_and_export_source_keywords($package);
    _export_symbols($package);
}

sub _instantiate_app {
    my $os = os();
    my $app_package = "Provision::DSL::App::$os";
    load $app_package;

    return $app_package->new_with_options;
}

sub _create_and_export_entity_keywords {
    my $package = shift;

    my $os = os();
    my %package_for;
    foreach my $entity_package (__PACKAGE__->entities) {
        my $entity_name = $entity_package;
        $entity_name =~ s{\A Provision::DSL::Entity::(?:_(\w+)\::)?}{}xms;
        next if $1 && $1 ne $os;

        $entity_name =~ s{::}{_}xmsg;

        next if exists $package_for{$entity_name}
             && length $package_for{$entity_name} > length $entity_package;
        $package_for{$entity_name} = $entity_package;
        
        # create class-types and coercions before loading entity modules
        if (!find_type_constraint($entity_name)) {
            class_type $entity_name,
                { class => $entity_package };
            coerce $entity_name,
                from 'Str',
                via { $entity_package->new({app => $app, name => $_}) };
        }
    }
    $app->_entity_package_for(\%package_for);

    while (my ($entity_name, $entity_package) = each %package_for) {
        load $entity_package;

        no strict 'refs';
        no warnings 'redefine';
        *{"${package}::${entity_name}"} = sub {
            if (defined wantarray) {
                return $app->get_cached_entity($entity_name, @_);
            } else {
                $app->create_entity($entity_name, @_)->execute;
            }
        };
    }
}

sub _create_and_export_source_keywords {
    my $package = shift;

    foreach my $source_package (__PACKAGE__->sources) {
        load $source_package;
        
        my $source_name = $source_package;
        $source_name =~ s{\A Provision::DSL::Source::}{}xms;
        
        no strict 'refs';
        no warnings 'redefine'; # occurs during test
        *{"${package}::${source_name}"}   = sub { $source_package->new(@_) };
        *{"${package}::\l${source_name}"} = *{"${package}::${source_name}"};
    }
}

sub _export_symbols {
    my $package = shift;

    foreach my $symbol (@EXPORT) {
        no strict 'refs';
        *{"${package}::${symbol}"} = *{"Provision::DSL::$symbol"};
    }
}

sub OS { goto &os }
sub Os { goto &os }
sub os {
    if ($^O eq 'darwin') {
        return 'OSX';
    } else {
        return 'Ubuntu'; ### FIXME: maybe wrong!
    }
}

sub Done { goto &done }
sub done {
    say 'Done.';
    
    exit;
}

=head1 AUTHOR

Wolfgang Kinkeldei, E<lt>wolfgang@kinkeldei.deE<gt>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
