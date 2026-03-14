# frozen_string_literal: true

require 'legion/extensions/default_mode_network/helpers/constants'
require 'legion/extensions/default_mode_network/helpers/wandering_thought'
require 'legion/extensions/default_mode_network/helpers/dmn_engine'
require 'legion/extensions/default_mode_network/runners/default_mode_network'

module Legion
  module Extensions
    module DefaultModeNetwork
      class Client
        include Runners::DefaultModeNetwork

        def initialize(dmn_engine: nil, **)
          @dmn_engine = dmn_engine || Helpers::DmnEngine.new
        end

        private

        attr_reader :dmn_engine
      end
    end
  end
end
