# frozen_string_literal: true

require 'rails'
require 'typedjs-rails'
require 'demo_mode/version'
require 'demo_mode/clever_sequence'
require 'demo_mode/config'
require 'demo_mode/engine'
require 'demo_mode/persona'

module DemoMode
  class << self
    delegate(*Config.configurations, to: :configuration)

    def enabled?
      ActiveModel::Type::Boolean::FALSE_VALUES.exclude?(ENV.fetch('DEMO_MODE', false)).tap do |enabled|
        webvalve_check! if enabled && defined?(WebValve)
      end
    end

    def table_name_prefix
      'demo_mode_'
    end

    def configure(&block)
      configuration.instance_eval(&block)
    end

    def add_persona(name = default_name, &block)
      configuration.persona(name, &block)
    end

    def callout_personas
      personas.select(&:callout?)
    end

    def standard_personas
      personas - callout_personas
    end

    def current_password
      Thread.current[:_demo_mode_password] ||= password.call
    end

    def current_password=(value)
      Thread.current[:_demo_mode_password] = value
    end

    private

    def configuration
      @configuration ||= Config.new
    end

    def webvalve_check!
      raise 'Demo Mode cannot be enabled unless WebValve is enabled.' unless WebValve.enabled?
    end

    def default_name
      persona_file = Pathname.new(caller_locations(2..2).first.path).relative_path_from(Rails.root.join(personas_path)).to_s
      raise "`add_persona` with no args only works from within '#{personas_path}'" if persona_file.start_with?('..')

      persona_file.delete_suffix('.rb').sub('/', ': ').gsub('/', ' — ')
    end
  end
end
