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

    def configure(&block)
      yield self
    end

    def bank
      @bank || DEFAULT_BANK
    end

    def bank=(value)
      raise UnknownBankError unless END_POINTS.keys.include?(value.to_sym)
      @bank = value
    end

    def env
      @env || DEFAULT_ENV
    end

    def env=(value)
      raise UnknownEnvError unless END_POINTS.first.last.include?(value.to_sym)
      @env = value
    end

    def target_url
      @target_url || END_POINTS[self.bank][self.env]
    end
  end
end
