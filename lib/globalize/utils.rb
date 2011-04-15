# encoding: utf-8
module Globalize
  class Utils
    class << self
      def model_dir
        @model_dir || "app/models"
      end

      def model_dir=(dir)
        @model_dir = dir
      end
    
      # Return a list of the model files to translate. If we have
      # command line arguments, they're assumed to be either
      # the underscore or CamelCase versions of model names.
      # Otherwise we take all the model files in the
      # model_dir directory.
      def get_model_files
        models = ARGV.dup
        models.shift
        models.reject!{|m| m.match(/^(.*)=/)}
        if models.empty?
          begin
            Dir.chdir(model_dir) do
              models = Dir["**/*.rb"]
            end
          rescue SystemCallError
            puts "No models found in directory '#{model_dir}'."
            exit 1;
          end
        end
        models
      end

      # Retrieve the classes belonging to the model names we're asked to process
      # Check for namespaced models in subdirectories as well as models
      # in subdirectories without namespacing.
      def get_model_class(file)
        require File.expand_path("#{model_dir}/#{file}") # this is for non-rails projects, which don't get Rails auto-require magic
        model = file.gsub(/\.rb$/, '').camelize
        parts = model.split('::')
        begin
          parts.inject(Object) {|klass, part| klass.const_get(part) }
        rescue LoadError, NameError
          Object.const_get(parts.last)
        end
      end
      
      def make_up(klass)    
        conn = klass.connection
        table_name = klass.translations_table_name
            
        if conn.table_exists?(table_name) # translated table exits
          columns = conn.columns(table_name)
          
          klass.translated_attribute_hash.each do |field|
            columns.each do |column|
              if column.name.to_sym == field[0] && column.type != field[1]
                klass.connection.change_column table_name, field[0], field[1]
              end
            end
            
            conn.add_column table_name, field[0], field[1] unless columns.map(&:name).include?(field[0].to_s)
          end
          
          columns.each do |column|
            conn.remove_column table_name, column.name if !klass.translated_attribute_names.include?(column.name.to_sym) && [:string, :text].include?(column.type) && column.name != "locale"
          end
        else
          klass.create_translation_table!(klass.translated_attribute_hash)
        end
      end
      
      def make_down(klass)
        klass.drop_translation_table! if klass.connection.table_exists?(klass.translations_table_name)
      end

      def init(kind)
        get_model_files.each do |file|
          begin
            klass = get_model_class(file)
            if klass < ::ActiveRecord::Base && !klass.abstract_class? && klass.respond_to?(:translated_attribute_names)
              case kind
                when :up then make_up(klass)
                when :down then make_down(klass)
              end
            end
          rescue Exception => e
            puts "Unable to #{kind} #{file}: #{e.inspect}"
          end
        end
      end
    
    end
  end
end
