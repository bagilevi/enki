require 'delegate'

module Enki
  class Config < SimpleDelegator
    def initialize(file_name)
      super(symbolize_keys(YAML::load(IO.read(file_name))))
    end

    def [](*path)
      get_from_env_var(*path) || get_from_config_file(*path)
    end

    def author_open_ids
      [self[:author, :open_id]].flatten.map {|uri| URI.parse(uri)}
    end

    def self.default
      Enki::Config.new(default_location)
    end

    def self.default_location
      "#{Rails.root}/config/enki.yml"
    end

    private

    def symbolize_keys(hash)
      hash.inject({}) do |options, (key, value)|
        options[(key.to_sym rescue key) || key] = value.is_a?(Hash) ? symbolize_keys(value) : value
        options
      end
    end

    def get_from_config_file(*path)
      path.inject(__getobj__()) {|config, item|
        config[item]
      }
    end

    def get_from_env_var(*path)
      v = ENV["ENKI_#{path.map{|s| s.to_s.upcase.gsub(/[^A-Z0-9]+/, '_')}.join('_')}"]
      string_to_appropriate_type(v)
    end

    def string_to_appropriate_type(v)
      case v
      when 'yes', 'true' then true
      when 'no', 'false' then false
      when /^[0-9]+$/ then v.to_i
      else v
      end
    end
  end
end
