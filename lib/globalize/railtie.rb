# encoding: utf-8
require 'rails'
require 'globalize'

module Globalize
  class Railtie < ::Rails::Railtie
    config.before_initialize do
      ActiveSupport.on_load :active_record do
        ::ActiveRecord::Base.send(:extend, Globalize::ActiveRecord::ActMacro)
      end
    end
    
    rake_tasks do
      load "tasks/globalize.rake"
    end
  end
end
