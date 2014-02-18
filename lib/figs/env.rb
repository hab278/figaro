require 'hashie'
module Figs
  module ENV
    extend self
    
    class EnvObjects < Hash
      include Hashie::Extensions::MethodAccess
    end
    
    def env
     @env ||= ::ENV
    end
    
    def env_objects
      @env_objects ||= EnvObjects.new
    end
    
    def set(key,value)
      env[key.to_s] = value.to_s
      env_objects[key] = value unless key.is_a?(String) && value.is_a?(String)
    end
    
    def delete(key)
      env.delete(key) {nil}
      if env_objects.key?(key)
        env_objects.delete(key) {nil}
      end
    end
    
    def []key
      update_env_objects
      return env_objects[key] if env_objects.key?(key)
      return env[key]
    end
    
    def []=(key,value)
      set(key, value)
    end
    
    def update_env_objects
      env_objects.keys.each do |key|
        env_objects.delete(key) unless env.key?(key)
      end
    end
    
    def method_missing(method, *args)
      if matches_env?(method) then env.send(method, args) end
      
      key, punctuation = extract_key_from_method(method)
      e = env
      if env_objects.keys.any? {|k| k.upcase.eql?(key.to_s.upcase) }
        e = env_objects
      end
      _, value = e.detect { |k, _| k.upcase == key }

      case punctuation
      when "!" then value || missing_key!(key)
      when "?" then !!value
      when nil then value
      else super
      end
    end

    def extract_key_from_method(method)
      method.to_s.upcase.match(/^(.+?)([!?=])?$/).captures
    end

    def missing_key!(key)
      raise MissingKey.new("Missing required Figaro configuration key #{key.inspect}.")
    end
    
    def respond_to?(method, *)
      return true if matches_env?(method)
      key, punctuation = extract_key_from_method(method)

      case punctuation
      when "!" then env.keys.any? { |k| k.upcase == key } || super
      when "?", nil then true
      else super
      end
    end
    
    def matches_env? meth
      env.respond_to?(meth)
    end
  end
end