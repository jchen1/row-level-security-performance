create extension if not exists "uuid-ossp";

create role application_user;

create table if not exists users_and_groups (
  id uuid default uuid_generate_v4() not null primary key,
  name text not null
);

create table if not exists items (
  id uuid default uuid_generate_v4() not null primary key,
  value text
);

create type permission_role as enum (
  'read',
  'write'
);

create table if not exists permissions (
  item_id uuid references items(id),
  user_or_group_id uuid references users_and_groups(id),
  role permission_role default 'read' not null
);

create index on permissions(item_id);
create index on permissions(user_or_group_id);

create view items_view
with (security_barrier)
as
  select items.*
  from permissions
  join items
    on item_id = items.id
    and user_or_group_id =
      any(regexp_split_to_array(current_setting('jwt.claims.roles'), ',')::uuid[]);

grant all
on schema public
to application_user;

grant all
on all tables in schema public
to application_user;

create policy permission_owner
on permissions
for all
to application_user
using (
  permissions.user_or_group_id =
      any(regexp_split_to_array(current_setting('jwt.claims.roles'), ',')::uuid[])
)
with check (
  permissions.user_or_group_id =
      any(regexp_split_to_array(current_setting('jwt.claims.roles'), ',')::uuid[])
  and permissions.role = 'write'
);

create or replace function insert_permission()
  returns trigger
  as $$
begin
  insert into permissions (item_id, user_or_group_id, role) values (
    new.id,
    (regexp_split_to_array(current_setting('jwt.claims.roles'), ',')::uuid[])[1],
    'write'
  );
  return new;
end
$$ language plpgsql;

create trigger insert_permission_trigger
after insert
on items
for each row
execute procedure insert_permission();

create or replace function create_role()
  returns trigger
  as $$
begin
  execute 'create role ' || quote_ident( new.id::text ) || ' inherit';
  execute 'grant application_user to ' || quote_ident( new.id::text );
  return new;
end
$$ language plpgsql;

create trigger insert_user_trigger
after insert
on users_and_groups
for each row
execute procedure create_role();
