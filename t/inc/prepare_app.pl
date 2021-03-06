use Provision::DSL::App;

use Provision::DSL::Entity::Dir;
use Provision::DSL::Entity::Rsync;
use Provision::DSL::Entity::User;
use Provision::DSL::Entity::Group;
use Provision::DSL::Entity::Path::Permission;

Provision::DSL::App
    ->instance
    ->entity_package_for(
        {
            Dir             => 'Provision::DSL::Entity::Dir',
            Rsync           => 'Provision::DSL::Entity::Rsync',
            User            => 'Provision::DSL::Entity::User',
            Group           => 'Provision::DSL::Entity::Group',
            Path_Permission => 'Provision::DSL::Entity::Path::Permission',
        }
    );
