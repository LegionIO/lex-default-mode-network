# frozen_string_literal: true

require 'securerandom'
require 'legion/extensions/default_mode_network/version'
require 'legion/extensions/default_mode_network/helpers/constants'
require 'legion/extensions/default_mode_network/helpers/wandering_thought'
require 'legion/extensions/default_mode_network/helpers/dmn_engine'
require 'legion/extensions/default_mode_network/runners/default_mode_network'
require 'legion/extensions/default_mode_network/client'

module Legion
  module Extensions
    module DefaultModeNetwork
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
