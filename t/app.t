use strict;
use warnings;
use Test::More;
use Test::Exception;
use Provision::DSL::Entity::File;
use Provision::DSL::Entity::TestingOnly;

use ok 'Provision::DSL::App';
use ok 'Provision::DSL::App::OSX';
use ok 'Provision::DSL::App::Ubuntu';

{
    package FakeEntity;
    use Moo;
    
    has executed       => (is => 'rw', default => sub { 0 });
    has need_privilege => (is => 'rw', default => sub { 0 });
    sub execute { $_[0]->executed(1) }
}

# OS reporting
{
    my $app = Provision::DSL::App->new;
    
    is $app->os, 'Unknown', 'base class reports OS as unknown';
    foreach my $os (qw(OSX Ubuntu)) {
        my $os_app = "Provision::DSL::App::$os"->new;
        is $os_app->os, $os, "os class reports OS as '$os'";
    }
}

# entity execution
{
    my $app = Provision::DSL::App->new;
    is_deeply $app->entities_to_execute, [], 'initially nothing to execute';
    
    my $e = FakeEntity->new;
    $app->add_entity_for_execution($e);
    is scalar @{$app->entities_to_execute}, 1, '1 entity to execute';
    ok !$app->execution_needs_privilege, 'no privilege needed for execution';
    $e->need_privilege(1);
    ok $app->execution_needs_privilege, 'privilege needed for execution';
    ok !$e->executed, 'entity not marked as executed';
    $app->execute_all_entities;
    ok $e->executed, 'entity marked as executed';
    
    done_testing; exit;
}

# creating entities
{
    my $app = Provision::DSL::App->new;
    
    foreach my $class (qw(TestingOnly File)) {
        $app->entity_package_for->{$class} = "Provision::DSL::Entity::$class";
    }
    
    dies_ok { $app->create_entity(Foo => {name => 'bla', app => $app}) }
        'creating an unknown entity fails';
    
    my $e1 = $app->create_entity(TestingOnly => {name => 'bla', app => $app});
    isa_ok $e1, 'Provision::DSL::Entity::TestingOnly';
    ok exists $app->_entity_cache->{TestingOnly}->{bla}, 'TestingOnly "bla" cached';
    
    dies_ok { $app->create_entity(TestingOnly => {name => 'bla', app => $app}) }
        'creating an entity twice fails';
    
    my $e2 = $app->get_cached_entity('TestingOnly');
    is $e1, $e2, 'loading a only-one-present entity works';
    
    my $e3 = $app->create_entity(TestingOnly => {name => 'foo', app => $app});
    dies_ok { $app->get_cached_entity('TestingOnly') }
        'loading an ambigous entity dies';
    
    my $e4 = $app->get_cached_entity(TestingOnly => 'bla');
    is $e1, $e4, 'loading a properly named entity works';
}


done_testing;
