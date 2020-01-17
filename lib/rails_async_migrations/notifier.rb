module RailsAsyncMigrations
  class Notifier
    def initialize
      @notifier = ::Slack::Notifier.new(webhook_url) if webhook_url
    end

    def processing(text)
      post(text: text, color: 'warning')
    end

    def failed(text)
      post(text: text, color: 'danger')
    end

    def done(text)
      post(text: text, color: 'good')
    end

    private

    def post(params)
      return puts "[VERBOSE] #{text}" if verbose?

      @notifier&.post(attachments: [params])
    end

    def webhook_url
      RailsAsyncMigrations.config.webhook_url.presence
    end

    def verbose?
      mode == :verbose
    end

    def mode
      RailsAsyncMigrations.config.mode
    end
  end
end
