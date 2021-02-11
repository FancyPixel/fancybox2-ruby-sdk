module Fancybox2
  module Migrations
    class Runner
      include Exceptions

      VERSION_REGEXP = /^(\d+)/.freeze

      class << self

        def extract_and_validate_version_from(migration_name)
          version = migration_name.to_s.scan(VERSION_REGEXP).flatten.first
          unless version
            raise ArgumentError, 'migration name must start with a positive integer number e.g: 1_do_something.rb'
          end

          version.to_i
        end

        def auto(migrations_folder, last_migrated_file_path: nil, logger: nil)
          # Try to read file content, rescue with nil
          content = File.read(last_migrated_file_path) rescue nil
          # Extract last run migration version
          last_run_migration_version = content.to_i

          runner = new(migrations_folder, logger: logger)
          last_migrated = runner.run last_migrated: last_run_migration_version
          # Update migration status file
          if last_migrated
            f = File.open last_migrated_file_path, 'w'
            f.write last_migrated.version
            f.close
          end
        end
      end

      attr_reader :files_path, :current_version, :migrations, :logger

      def initialize(files_path, logger: nil)
        @files_path = files_path
        @logger = logger || ::Logger.new(STDOUT)

        load_migrations
      end

      # @param from a valid migration name or version
      # @param to a valid migration name or version
      # @return last run migration
      def run(from: nil, to: nil, last_migrated: nil)
        if from && last_migrated
          logger.warn "#{self.class}#run - Both 'from' and 'last_migrated' params given. Only 'last_migrated' considered"
        end
        # Extract and validate versions
        from = self.class.extract_and_validate_version_from(from || last_migrated || 0)
        # This works independently from the direction if migrations' folder contains only migrations of last installed version
        to = self.class.extract_and_validate_version_from (to || @migrations.last.version)
        # Select migrations to run
        to_run, direction = migrations_to_run from, to
        # If last_migrated param has been provided, remove some migration from the list depending on direction
        if last_migrated && to_run.any?
          if direction == :up && last_migrated == to_run.first.version
            to_run.shift
          elsif direction == :down
            # We surely have at least 2 migrations in the array, otherwise the direction would've been :up
            to_run.pop
          end
        end
        to_run.each do |migration|
          logger.info "Running migration #{migration.name}"
          migration.send direction
        end

        to_run.last
      end

      def load_migrations
        # Load files from files_path and create classes
        @migrations = Dir[File.join(File.expand_path(files_path), '**', '*.rb')].map do |file_path|
          migration_name = File.basename(file_path)
          klass = Class.new(Base)
          klass.class_eval(File.read(file_path), file_path)
          klass.freeze
          klass.new migration_name
        end.sort_by { |migration| migration.version }
      end

      # Select migrations to run depending given a starting and an ending one
      def migrations_to_run(from, to)
        selected = []
        direction = from <= to ? :up : :down
        @migrations.each do |m|
          # downgrading - Break if we already arrived to "from" migration (e.g from=4, to=2 => 1, >2<, 3, *4*, 5)
          break if (from > to) && (m.version > from)
          # upgrading - Break if we already arrived to "to" migration (e.g from=2, to=4 => 1, *2*, 3, >4<, 5)
          break if (from < to) && (m.version > to)
          # downgrading - Skip until we arrive to "to" migration (e.g from=4, to=2 => 1, >2<, 3, *4*, 5)
          next if (from > to) && (m.version < to)
          # upgrading - Skip until we arrive to "from" migration (e.g from=2, to=4 => 1, *2*, 3, >4<, 5)
          next if (from <= to) && (m.version < from)
          # Break if we're already out of range
          break if (m.version > from && m.version > to)

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
