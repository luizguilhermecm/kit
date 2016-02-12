daily tasks
-----------

The idea is having a daily-tasks, a list of things to be done every day.
The list has as main goal; remember of doing it until that thing came to be an
habit or get away for good.

#### Main tasks of day

Maybe create a big task which has small tasks inside, a main tast could be
the time of day such 'morning' or things to do before sleep.


#### database considerations

Having a main task may increase the complexity a bit, it will implicate in
a _nxm_ relationship or a relationship with the table itself using some kind
of flag, and would be a nxm eather way.


#### sketch

table: `daily-tasks`

table: `main_task`

The idea of having decomposed tasks will be keep in stand by for a while, for
speed up this feature.


```
CREATE TABLE daily_task (
id SERIAL PRIMARY KEY,
text TEXT NOT NULL,
user_id INTEGER NOT NULL,
created_at TIMESTAMP DEFAULT now(),
updated_at TIMESTAMP DEFAULT now(),
is_valid BOOLEAN DEFAULT TRUE
);

CREATE TABLE daily_task_journal (
id SERIAL PRIMARY KEY,
daily_task_id INTEGER NOT NULL,
action VARCHAR,
text TEXT NOT NULL,
created_at TIMESTAMP DEFAULT now(),
updated_at TIMESTAMP DEFAULT now()
);
```



## stand-by

```
table: `decomposed_task`

```sql
CREATE TABLE decomposed_task (
  id serial primary key,
  main_task_id not null,
  text text not null,
  created_at timestamp default now(),
  flag_deleted boolean default false,
  uid integer
);

CREATE TABLE main_task (
  id serial primary key,
  text text not null,
  created_at timestamp default now(),
  flag_deleted boolean default false,
  uid integer
);
```
