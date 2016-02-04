daily tasks
-----------

The idea is having a daily-tasks, a list of things to be done every day.
The list has the goal of remember of doing it.

#### Main tasks of day

Maybe create a big task which has small tasks inside, a main tast could be
the time of day such 'morning' or things to do before sleep.


#### database considerations

Having a main task may increase the complexity a bit, it will implicate in
a _nxm_ relationship.


#### sketch

table: `daily-tasks`

table: `main_task`

table: `decomposed_task`


```sql
CREATE TABLE main_task (
  id serial primary key,
  text text not null,
  created_at timestamp default now(),
  flag_deleted boolean default false,
  uid integer
);
```

```sql
CREATE TABLE decomposed_task (
  id serial primary key,
  main_task_id not null,
  text text not null,
  created_at timestamp default now(),
  flag_deleted boolean default false,
  uid integer
);
```





id
text
created_at
flag_deleted
deleted_at
uid
tag_id
flag_do_it
flag_done
done_at
