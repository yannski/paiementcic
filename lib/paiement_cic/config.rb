module PaiementCic
  class Config
    attr_accessor :hmac_key, :tpe, :societe
    attr_writer :target_url

    def initialize(attributes = {}, &block)
      if block_given?
        configure(&block)
      else
        attributes.each do |name, value|
          setter = "#{name}="
          next unless respond_to?(setter)
          send(setter, value)
        end
      end
    end

    ["bank", "env"].each do |m|
      define_method(m) { instance_variable_get("@#{m}") || Object.const_get("default_#{m}".upcase) }
      define_method "#{m}=" do |value|
        raise Object.const_get("Unknown#{m.capitalize}Error") unless END_POINTS.select{|k,v| k == value.to_sym or v.include?(value.to_sym)}.any?
        instance_variable_set("@#{m}", value)
      end
    end

    def configure(&block)
      yield self
    end

    def target_url
      @target_url || END_POINTS[self.bank][self.env]
    end
    
  end
end
