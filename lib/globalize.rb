require 'active_record'
require 'patches/active_record/xml_attribute_serializer'
require 'patches/active_record/query_method'

module Globalize
  autoload :ActiveRecord, 'globalize/active_record'
  autoload :Versioning,   'globalize/versioning'
  autoload :Utils,   'globalize/utils'

  mattr_accessor :available_locales

  class << self
    def locale
      read_locale || I18n.locale
    end

    def locale=(locale)
      set_locale(locale)
    end

    def with_locale(locale, &block)
      previous_locale = read_locale
      set_locale(locale)
      result = yield
      set_locale(previous_locale)
      result
    end

    def available_locales
      @@available_locales || I18n.backend.available_locales
    end

    def fallbacks?
      I18n.respond_to?(:fallbacks)
    end

    def fallbacks(locale = self.locale)
      fallbacks? ? I18n.fallbacks[locale] : [locale.to_sym]
    end

    protected

      def read_locale
        Thread.current[:globalize_locale]
      end

      def set_locale(locale)
        Thread.current[:globalize_locale] = locale
      end
  end
end

require 'globalize/railtie'
