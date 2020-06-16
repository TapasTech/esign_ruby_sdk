require 'esign/configuration'
require 'json'
require 'esign/identity'
require 'esign/contract'

module Esign

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
