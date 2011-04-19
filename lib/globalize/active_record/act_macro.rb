module Globalize
  module ActiveRecord
    module ActMacro
      def translates(*attr_names)
        return if translates?

        options = {}
        options[:table_name] ||= "#{table_name.singularize}_translations"
        
        names = attr_names.extract_options!

        class_inheritable_accessor :translated_attribute_names, :translated_attribute_hash, :translation_options
        self.translated_attribute_names = names.keys.map(&:to_sym)
        self.translated_attribute_hash  = names
        self.translation_options        = options

        include InstanceMethods, Accessors
        extend  ClassMethods, Migration

        has_many :translations, :class_name  => translation_class.name,
                                :foreign_key => class_name.foreign_key,
                                :dependent   => :delete_all,
                                :extend      => HasManyExtensions

        after_save :save_translations!
        before_save :update_checkers!
        
        scope :with_locale, lambda {|locale| where(["is_locale_#{locale} = 1"])}

        names.keys.each { |attr_name| translated_attr_accessor(attr_name) }
      end

      def class_name
        class_name = table_name[table_name_prefix.length..-(table_name_suffix.length + 1)].camelize
        pluralize_table_names ? class_name.singularize : class_name
      end

      def translates?
        included_modules.include?(InstanceMethods)
      end
    end

    module HasManyExtensions
      def find_or_initialize_by_locale(locale)
        with_locale(locale.to_s).first || build(:locale => locale.to_s)
      end
    end
  end
end
