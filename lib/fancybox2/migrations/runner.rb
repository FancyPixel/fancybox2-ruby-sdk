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
        puts "from: #{from}, to: #{to}, last_migrated: #{last_migrated}"
        # Select migrations to run
        to_run, direction = migrations_to_run from, to
        # If last_migrated has been specified and direction is :up, remove first migration
        if last_migrated && direction == :up
          to_run.shift
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
          puts m.version
          # Edge case, no migrations to run
          break if from == to
          # downgrading - Break if we already arrived to "from" migration (e.g from=4, to=2 => 1, >2<, 3, *4*, 5)
          break if (from > to) && (m.version > from)
          # upgrading - Break if we already arrived to "to" migration (e.g from=2, to=4 => 1, *2*, 3, >4<, 5)
          break if (from < to) && (m.version > to)
          # downgrading - Skip until we arrive to "to" migration (e.g from=4, to=2 => 1, >2<, 3, *4*, 5)
          next if (from > to) && (m.version < to)
          # upgrading - Skip until we arrive to "from" migration (e.g from=2, to=4 => 1, *2*, 3, >4<, 5)
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
