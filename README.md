# Postgressor

Get tired of typing the same commands over and over like creating Postgres user, database, creating and restoring database backups? Postgressor allow you to manage your (Postgres) application database and user within simple commands:

```
$ postgressor -h
Commands:
  postgressor createuser      # Create app database user
  postgressor dropuser        # Drop app database user
  postgressor createdb        # Create app database
  postgressor dropdb          # Drop app database
  postgressor dumpdb          # Dump (backup) app database
  postgressor restoredb       # Restore app database from backup

  postgressor --version, -v   # Print the version
  postgressor help [COMMAND]  # Describe available commands or one specific command
```

All what you need is DATABASE_URL in format like: `DATABASE_URL="postgres://app_user:app_user_pass@host/app_db_name"`. Also Postgressor automatically check `.env` file (if present) **to read DATABASE_URL from there.**

## Installation

> Posgressor requires Ruby `>= 2.3.0`.

To install:

```
$ gem install postgressor
```

## Usage

> Use `VERBOSE=true` env option (used in examples below) to print postgres commands which will be executed

### createuser and dropuser

To create user:

> You can provide `--superuser` option to create user as SUPERUSER

```
$ DATABASE_URL="postgres://app_user:123456@localhost/app_db" VERBOSE=true postgressor createuser

Executing: sudo -i -u postgres psql -c CREATE USER app_user WITH CREATEDB LOGIN PASSWORD '123456';
CREATE ROLE
Created user app_user
```

To drop user:

```
$ DATABASE_URL="postgres://app_user:123456@localhost/app_db" VERBOSE=true postgressor dropuser

Executing: sudo -i -u postgres dropuser app_user
Dropped user app_user
```

### createdb and dropdb

To create database:

```
$ DATABASE_URL="postgres://app_user:123456@localhost/app_db" VERBOSE=true postgressor createdb

Executing: PGPASSWORD=123456 createdb app_db -h localhost -U app_user
Created database app_db
```

To drop database:

```
$ DATABASE_URL="postgres://app_user:123456@localhost/app_db" VERBOSE=true postgressor dropdb

Executing: PGPASSWORD=123456 dropdb app_db -h localhost -U app_user
Dropped database app_db
```

### dumpdb and restoredb

To perform database backup to the current directory:

```
$ DATABASE_URL="postgres://app_user:123456@localhost/app_db" VERBOSE=true postgressor dumpdb

Executing: PGPASSWORD=123456 pg_dump app_db -Fc --no-acl --no-owner -f app_db.dump -h localhost -U app_user
Dumped database app_db to app_db.dump file
```

To restore database from backup file:

> Note: sometimes backup restore will fail if current user is not superuser, so there is option `--switch_to_superuser` to temporary switch user to SUPERUSER

> Note: recreate (drop and create) database before restore to omit some possible errors

```
$ DATABASE_URL="postgres://app_user:123456@localhost/app_db" VERBOSE=true postgressor restoredb app_db.dump --switch_to_superuser

Executing: sudo -i -u postgres psql -c ALTER ROLE app_user SUPERUSER;
ALTER ROLE
Set user app_user to SUPERUSER
Executing: PGPASSWORD=123456 pg_restore app_db.dump -d app_db --no-acl --no-owner --verbose -h localhost -U app_user
pg_restore: connecting to database for restore
pg_restore: creating SCHEMA "public"
pg_restore: creating COMMENT "SCHEMA public"
pg_restore: creating EXTENSION "plpgsql"
pg_restore: creating COMMENT "EXTENSION plpgsql"
Restored database app_db from app_db.dump file
Executing: sudo -i -u postgres psql -c ALTER ROLE app_user NOSUPERUSER;
ALTER ROLE
Set user app_user to NOSUPERUSER
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
