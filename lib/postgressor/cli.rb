require 'uri'
require 'open3'
require 'thor'
require 'dotenv/load'

module Postgressor
  class CLI < Thor
    # https://www.postgresql.org/docs/current/app-createuser.html
    desc "createuser", "Create app database user"
    option :superuser, type: :string, banner: "Create user as superuser"
    def createuser
      preload!

      # Use psql `CREATE USER` instead of `createuser` CLI command, to automatically provide user password:
      is_superuser = options[:superuser] ? 'SUPERUSER' : nil
      psql_create_command = "CREATE USER #{@conf[:user]} WITH CREATEDB LOGIN #{is_superuser} PASSWORD '#{@conf[:password]}';"

      if system "sudo", "-i", "-u", "postgres", "psql", "-c", psql_create_command
        say "Created user #{@conf[:user]}", :green
      end
    end

    # https://www.postgresql.org/docs/current/app-dropuser.html
    desc "dropuser", "Drop app database user"
    def dropuser
      preload!

      if system "sudo", "-i", "-u", "postgres", "dropuser", @conf[:user]
        say "Dropped user #{@conf[:user]}", :green
      end
    end

    ###

    # https://www.postgresql.org/docs/current/app-createdb.html
    desc "createdb", "Create app database"
    def createdb
      preload!

      if system env, "createdb", @conf[:db], *@pg_cli_args
        say "Created database #{@conf[:db]}", :green
      end
    end

    # https://www.postgresql.org/docs/current/app-dropdb.html
    desc "dropdb", "Drop app database"
    def dropdb
      preload!

      if system env, "dropdb", @conf[:db], *@pg_cli_args
        say "Dropped database #{@conf[:db]}", :green
      end
    end

    ###

    # https://www.postgresql.org/docs/current/app-pgdump.html
    desc "dumpdb", "Dump (backup) app database"
    def dumpdb
      preload!

      dump_file_name = "#{@conf[:db]}.dump"
      if system env, "pg_dump", @conf[:db], *@pg_cli_args, "-Fc", "--no-acl", "--no-owner", "-f", dump_file_name
        say "Dumped database #{@conf[:db]} to #{dump_file_name} file", :green
      end
    end

    # https://www.postgresql.org/docs/current/app-pgrestore.html
    desc "restoredb", "Restore app database from backup"
    def restoredb(dump_file_path)
      preload!

      if system env, "pg_restore", dump_file_path, "-d", @conf[:db], *@pg_cli_args, "--no-acl", "--no-owner", "--verbose"
        say "Restored database #{@conf[:db]} from #{dump_file_path} file", :green
      end
    end

    ###

    map %w[--version -v] => :__print_version
    desc "--version, -v", "Print the version"
    def __print_version
      puts VERSION
    end

    private

    def env
      { "PGPASSWORD" => @conf[:password] }
    end

    def preload!
      url = ENV["DATABASE_URL"]
      raise "Env variable DATABASE_URL is not provided" if url.nil? || url.strip.empty?

      uri = URI.parse(url)
      raise "DB adapter is not postgres" if uri.scheme != "postgres"

      @conf = {
        url: url,
        db: uri.path.sub("/", ""),
        host: uri.host,
        port: uri.port,
        user: uri.user,
        password: uri.password
      }

      @pg_cli_args = ["-h", @conf[:host], "-U", @conf[:user]]
      @pg_cli_args += ["-p", @conf[:port].to_s] if @conf[:port]
    end
  end
end
