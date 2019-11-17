# Dockerized SQL-Ledger

## Audience

The content of this directory is addressed at DevOps interested in
Docker-based setups of SQL-Ledger.

## System requirements

* Docker
* `docker-compose`
* For local development: Normal user account with permission to execute 
Docker commands


## Local development

The goal is to get a SQL-Ledger container that operates directly
on the sources (with a bind mount), so that any change of the sources
will direcly affect the behaviour of the application.

### Prerequisites for local development

At the very first time, enter this folder and run

    ./env-setup.sh

This will set up a file ~/.sql-ledger.env containing
environment variables needed for `docker-compose` and a symbolic
link '.env' to this file. The `.env` file is the one that
`docker-compose` is looking for; the linking is just for
persistency reasons. 

For the moment, all settings should be fine. We'll come back to that later.


### Manage development containers via `ledgerctl`

    ./ledgerctl develop.yml up

When called for the first time, the images have to be build, which
will take some time. After a few minutes,
the application should be reachable at http://localhost:4293,
but there are no accounts and the admin account is not yet usable.
To initialize, call

    ./ledgerctl develop.yml init

This will setup the application root account with password 'secret';
you can choose another one with `--rootpw PASSWORD`.

After that you can admin-login at http://localhost:4293/admin.pl.

Now you could create datasets, create users, ...
The name of the database host is "`db`", the name of the
database user is "`sql-ledger`". (You can change the latter 
in your `.env` file, but if you already have started a database
container you would have to stop it and remove the postgresql
volume before recreating.)

To bring everything down, call

    ./ledgerctl develop.yml down

or even

    ./ledgerctl develop.yml reset

(which additionally removes the PostgreSQL data volume).


### Working with setups

Now we have an "empty" Ledger application. For development puposes it
is very useful
to quickly "switch" to different scenarios (datasets + users).
This can be achieved with _setups_.

What you need is a folder for appropriate PostgreSQL dumps and a
folder for setup configs (both somewhere "outside" of this project). 
Say (for example):

* `~/projects/sql-ledger/ledgersetup/configs`
* `~/projects/sql-ledger/ledgersetup/dumps`

At first you have to configure these in your `~/.sql-ledger.env`:

```sh
[...]
LEDGERSETUP_CONFIG_PATH=~/projects/sql-ledger/ledgersetup/configs
LEDGERSETUP_DUMPS_PATH=~/projects/sql-ledger/ledgersetup/dumps
[...]
```

Restart the application (because these paths will be bind-mounted 
read-only into the web container):

    ./ledgerctl develop.yml up

A setup config is written in YAML. We show this with an example,
say `setup1.yml`:

```yaml
---
dumps:
  - 20190507/somedump.bz2
  - 20190507/someotherdump.bz2
force_recreate: 1
users:
  - { name: de, pass: de, lang: de }
  - { name: gb, pass: gb, lang: gb }
```

The `dumps` are relative paths in your `LEDGERSETUP_DUMPS_PATH` folder.

Having that, you could run

    ./ledgerctl develop.yml setup setup1.yml

After that, you can work with this setup. Besides, you can query the latest 
setup info via web interface at any time:

    http://localhost:4293/ledgersetup/runinfo


#### Setup configuration syntax

Aside from what you already have seen in the example above, you can use
the following special patterns in dump paths:

* Shell globbing with "`*`"
* *One* use of the pattern `{{ latest_nonempty_dir() }}`
* Use of the pattern `{{ build_time(%Y%m%d) }}` (or any other `strftime` expression)
* Use of the pattern `{{ param(KEY) }}` (see `ledgersetup.pl --param KEY=VALUE`)


## Staging builds

The goal here is to get a SQL-Ledger container that has a copy of the 
sources in it. A suitable compose file  is `staging.yml`, and if you want
to manage different instances (e.g. in a Jenkins CI environment),
you should add a project name (here: `staging-test1`):

    ./ledgerctl -p staging-test1 staging.yml port.yml up --build

Then the same with `init/setup/...`.

If you don't need a directly accesible port (e.g. in a reverse proxy setup),
just omit the `port.yml`.

This staging build is configurable with the following environment
variables:

* `LEDGER_POSTGRES_USER`
* `LEDGERSETUP_CONFIG_PATH`
* `LEDGERSETUP_DUMPS_PATH`
* `LEDGER_PORT` (if needed)

If you want to test this in your development environment, please ensure that
there are no conflicting values in your `.env` file!
