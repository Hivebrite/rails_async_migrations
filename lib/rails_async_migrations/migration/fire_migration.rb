# we check the state of the queue and launch run worker if needed
module RailsAsyncMigrations
  module Migration
    class FireMigration
      attr_reader :migration

      def initialize(migration_id)
        @notifier = Notifier.new
        @tracer = Tracer.new
        @migration = AsyncSchemaMigration.find(migration_id)
      end

      def perform
        return if done?

        process!
        run_migration
        done!

        check_queue
      end

      private

      def check_queue
        Workers.new(:check_queue).perform
      end

      def run_migration
        Migration::Run.new(migration.direction, migration.version).perform
      rescue Exception => exception
        failed_with! exception
        raise
      end

      def done?
        if migration.reload.state == 'done'
          msg = "Migration #{migration.version} is already `done`, cancelling fire"

          @tracer.verbose(msg)
          @notifier.failed(msg)
          return true
        end
      end

      def process!
        @notifier.processing("Migration #{migration.version} is being processed")
        migration.update! state: 'processing'
      end

      def done!
        migration.update! state: 'done'
        msg = "Migration #{migration.version} was successfully processed"

        @tracer.verbose(msg)
        @notifier.done(msg)
        migration.reload
      end

      def base_notifier_message
        @migration.version
      end

      def failed_with!(error)
        migration.update! state: 'failed'
        msg = "Migration #{migration.version} failed with exception `#{error}`"
        @notifier.failed(msg)
        Tracer.new.verbose(msg)
      end
    end
  end
end
