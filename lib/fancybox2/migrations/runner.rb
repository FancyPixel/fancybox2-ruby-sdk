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

      def initialize(files_path, current_version = nil)
        @files_path = files_path
        if current_version
          @current_version = self.class.extract_and_validate_version_from current_version
        end

        load_migrations
      end

      def run(from: nil, to: nil)
        # Select migrations to run
        to_run = migrations_to_run from, to
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

      # Select migrations to run depending on direction
      # :up selects only migration with a version greater than current_version
      # :down selects migrations with a version lower_or_equal_to current_version
      def migrations_to_run(from, to)
        selected = []
        @migrations.each do |m|
          # Break if we already arrived to "from" migration
          break if (from > to) && (m.version > from)
          # Break if we already arrived to "to" migration
          break if (from < to) && (m.version > to)
          # Skip until we arrive to "from" migration
          next if (from < to) && (m.version < from)

          if m.version <= from
            selected.prepend m
          else
            selected.append m
          end
        end

        selected
      end
    end
  end
end
