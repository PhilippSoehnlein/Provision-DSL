use strict;
use warnings;
use Test::More;
use Test::Exception;

use ok 'Provision::DSL::Entity';

{
    #no strict 'refs';
    no warnings 'redefine';
    *Provision::DSL::Types::os = sub { 'OSX' };
}

# default state and default inspector
{
    is +Provision::DSL::Entity->new(name => 'bla')->state, 'current',
        'default state is "current"';
}

# provided inspector
{
    my $entity = Provision::DSL::Entity->new(name => 'bla', inspector => 'Always');
    is $entity->state, 'outdated',
        'Always changes state to "outdated"';

    is_deeply $entity->inspector, ['Provision::DSL::Inspector::Always', {}],
        'inspector class and args look good';

    isa_ok $entity->inspector_instance, 'Provision::DSL::Inspector::Always',
        'inspector is instantiated right';

    is $entity->inspector_instance->entity, $entity,
        'inspector->entity points to entitiy';

    ok !$entity->need_privilege, 'no privilege needed';
}

# privilege
{
    # no strict 'refs';
    no warnings 'redefine';
    local *Provision::DSL::Inspector::Never::need_privilege = sub { 1 };

    ok +Provision::DSL::Entity->new(name => 'bla')->need_privilege,
        'privilege needed when inspector requests it';
}

# states/privilege depending on parent/child
{
    my @testcases = (
        # parent         child          expect
        [ 'missing',  0, 'current',  0, 'missing',  0 ],
        [ 'missing',  0, 'outdated', 0, 'missing',  0 ],
        [ 'missing',  0, 'missing',  0, 'missing',  0 ],
        
        [ 'outdated', 0, 'current',  0, 'outdated', 0 ],
        [ 'outdated', 0, 'outdated', 0, 'outdated', 0 ],
        [ 'outdated', 0, 'missing',  0, 'outdated', 0 ],
        
        [ 'current',  1, 'current',  0, 'current',  1 ],
        [ 'current',  0, 'outdated', 1, 'outdated', 1 ],
        [ 'current',  1, 'missing',  1, 'outdated', 1 ],
    );

    foreach my $testcase (@testcases) {
        my ($pstate, $ppriv,
            $cstate, $cpriv,
            $estate, $epriv) = @$testcase;
        my $name = join ',', @$testcase;

        my $pe = Provision::DSL::Entity->new(
            name           => 'parent',
            inspector      => [ 'Always', state => $pstate, need_privilege => $ppriv ],
        );

        my $ce = Provision::DSL::Entity->new(
            name           => 'child',
            parent         => $pe,
            inspector      => [ 'Always', state => $cstate, need_privilege => $cpriv ],
        );

        $pe->add_child($ce);
        is $pe->nr_children, 1, "$name: parent has 1 child";
        is_deeply $pe->children, [$ce], "$name: child array-ref looks good";
        is_deeply [ $pe->all_children ], [$ce], "$name: child array looks good";

        is $pe->state, $estate, "$name: state is '$estate'";
        if ($epriv) {
            ok $pe->need_privilege, "$name: need privilege";
        } else {
            ok !$pe->need_privilege, "$name: do not need privilege";
        }
    }
}

# check is_ok depending on wanted/state
{
    my @testcases = (
        # state         wanted  is_ok
        [ 'missing',    0,      1],
        [ 'missing',    1,      0],
        [ 'outdated',   0,      0],
        [ 'outdated',   1,      0],
        [ 'current',    0,      0],
        [ 'current',    1,      1],
    );
    
    foreach my $testcase (@testcases) {
        my ($state, $wanted, $is_ok) = @$testcase;
        my $name = join ',', @$testcase;
        
        my $e = Provision::DSL::Entity->new(
            name      => 'entity',
            wanted    => $wanted,
            inspector => [ 'Always', state => $state ],
        );

        if ($is_ok) {
            ok $e->is_ok, "$name: is ok";
        } else {
            ok !$e->is_ok, "$name: is not ok";
        }
    }
}

# check calling installer methods
{
    my @testcases = (
        # ...
    );
}

done_testing;
