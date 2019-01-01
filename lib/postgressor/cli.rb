require 'uri'
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
      is_superuser = "SUPERUSER" if options[:superuser]
      psql_command = "CREATE USER #{@conf[:user]} WITH CREATEDB LOGIN #{is_superuser} PASSWORD '#{@conf[:password]}';"

      command = %W(sudo -i -u postgres psql -c #{psql_command})
      if execute command
        say "Created user #{@conf[:user]}", :green
      end
    end

    # https://www.postgresql.org/docs/current/app-dropuser.html
    desc "dropuser", "Drop app database user"
    def dropuser
      preload!

      command = %W(sudo -i -u postgres dropuser #{@conf[:user]})
      if execute command
        say "Dropped user #{@conf[:user]}", :green
      end
    end

    ###

    # https://www.postgresql.org/docs/current/app-createdb.html
    desc "createdb", "Create app database"
    def createdb
      preload!

      command = ["createdb", @conf[:db]] + @pg_cli_args
      if execute command, with_env: true
        say "Created database #{@conf[:db]}", :green
      end
    end

    # https://www.postgresql.org/docs/current/app-dropdb.html
    desc "dropdb", "Drop app database"
    def dropdb
      preload!

      command = ["dropdb", @conf[:db]] + @pg_cli_args
      if execute command, with_env: true
        say "Dropped database #{@conf[:db]}", :green
      end
    end

    ###

    # https://www.postgresql.org/docs/current/app-pgdump.html
    desc "dumpdb", "Dump (backup) app database"
    def dumpdb
      preload!

      dump_file_name = "#{@conf[:db]}.dump"
      command = %W(pg_dump #{@conf[:db]} -Fc --no-acl --no-owner -f #{dump_file_name}) + @pg_cli_args

      if execute command, with_env: true
        say "Dumped database #{@conf[:db]} to #{dump_file_name} file", :green
      end
    end

    # https://www.postgresql.org/docs/current/app-pgrestore.html
    desc "restoredb", "Restore app database from backup"
    option :switch_to_superuser, type: :string, banner: "Temporary switch user to SUPERUSER while restoring db"
    def restoredb(dump_file_path)
      preload!

      set_user_to_superuser if options[:switch_to_superuser]

      command = %W(pg_restore #{dump_file_path} -d #{@conf[:db]} --no-acl --no-owner --verbose) + @pg_cli_args
      if execute command, with_env: true
        say "Restored database #{@conf[:db]} from #{dump_file_path} file", :green
      end

      set_user_to_nosuperuser if options[:switch_to_superuser]
    end

    ###

    map %w[--version -v] => :__print_version
    desc "--version, -v", "Print the version"
    def __print_version
      puts VERSION
    end

    private

    def set_user_to_superuser
      psql_command = "ALTER ROLE #{@conf[:user]} SUPERUSER;"
      command = %W(sudo -i -u postgres psql -c #{psql_command})
      if execute command
        say "Set user #{@conf[:user]} to SUPERUSER", :green
      end
    end

    def set_user_to_nosuperuser
      psql_command = "ALTER ROLE #{@conf[:user]} NOSUPERUSER;"
      command = %W(sudo -i -u postgres psql -c #{psql_command})
      if execute command
        say "Set user #{@conf[:user]} to NOSUPERUSER", :green
      end
    end

    def execute(command, with_env: false)
      if with_env
        verbose_command = env.map { |k, v| "#{k}=#{v}" } + command
        say("Executing: #{verbose_command.join(' ')}", :yellow) if ENV["VERBOSE"] == "true"

        system env, *command
      else
        say("Executing: #{command.join(' ')}", :yellow) if ENV["VERBOSE"] == "true"
        system *command
      end
    end

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
