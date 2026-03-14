# frozen_string_literal: true

require 'legion/extensions/context/version'
require 'legion/extensions/context/helpers/constants'
require 'legion/extensions/context/helpers/frame'
require 'legion/extensions/context/helpers/context_manager'
require 'legion/extensions/context/runners/context'
require 'legion/extensions/context/client'

module Legion
  module Extensions
    module Context
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
