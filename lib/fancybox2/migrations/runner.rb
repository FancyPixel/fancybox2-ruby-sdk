module Fancybox2
  module Migrations
    class Runner
      include Exceptions

      VERSION_REGEXP = /^(\d{14})/.freeze

      class << self

        def extract_and_validate_version_from(migration_name)
          version = migration_name.to_s.scan(VERSION_REGEXP).flatten.first
          unless version
            raise ArgumentError, 'migration version must be a 14 digits integer'
          end

          version.to_i
        end
      end

      attr_reader :files_path, :current_version, :migrations

      def initialize(files_path)
        @files_path = files_path

        load_migrations
      end
      
      # @param from a valid migration name or version
      # @param to a valid migration name or version
      def run(from: nil, to: nil)
        # Extract and validate versions
        from = self.class.extract_and_validate_version_from from
        to = self.class.extract_and_validate_version_from to
        # Select migrations to run
        to_run, direction = migrations_to_run from, to
        to_run.each do |migration|
          migration.send direction
        end
      end

      def load_migrations
        # Load files from files_path and create classes
        @migrations = Dir[File.join(File.expand_path(files_path), '**', '*.rb')].sort.map do |f_path|
          migration_name = File.basename(f_path)
          klass = Class.new(Base)
          klass.class_eval(File.read(f_path), f_path)
          klass.freeze
          klass.new migration_name
        end
      end

      # Select migrations to run depending given a starting and an ending one
      def migrations_to_run(from, to)
        selected = []
        direction = from <= to ? :up : :down
        @migrations.each do |m|
          break if (from == to)
          # Break if we already arrived to "from" migration
          break if (from > to) && (m.version > from)
          # Break if we already arrived to "to" migration
          break if (from < to) && (m.version > to)
          # Skip until we arrive to "to" migration
          next if (from > to) && (m.version < to)
          # Skip until we arrive to "from" migration
          next if (from < to) && (m.version < from)

          if m.version <= from
            selected.prepend m
          else
            selected.append m
          end
        end

        [selected, direction]
      end
    end
  end
end
