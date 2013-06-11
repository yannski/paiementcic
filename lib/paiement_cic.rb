require 'paiement_cic/tpe'
require 'paiement_cic/railtie' if defined?(Rails)

require 'digest/sha1'

class String
  def ^(other)
    raise ArgumentError, "Can't bitwise-XOR a String with a non-String" \
      unless other.kind_of? String
    raise ArgumentError, "Can't bitwise-XOR strings of different length" \
      unless self.length == other.length
    result = (0..self.length-1).collect { |i| self[i].ord ^ other[i].ord }
    result.pack("C*")
  end
end

module PaiementCic
  API_VERSION = "3.0"
  DATE_FORMAT = "%d/%m/%Y:%H:%M:%S"

  END_POINTS = {
    cic: {
      production: 'https://ssl.paiement.cic-banques.fr/paiement.cgi',
      test: 'https://ssl.paiement.cic-banques.fr/test/paiement.cgi'
    },
    cm: {
      production: 'https://paiement.creditmutuel.fr/paiement.cgi',
      test: 'https://paiement.creditmutuel.fr/test/paiement.cgi'
    }
  }
  DEFAULT_BANK = :cm
  DEFAULT_ENV = :test

  class << self
    attr_accessor :hmac_key, :tpe, :societe
    attr_writer :target_url

    def configure(&block)
      yield(self) if block_given?
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

    def hmac_sha1(key, data)
      length = 64

      if (key.length > length)
        key = [Digest::SHA1.hexdigest(key)].pack("H*")
      end

      key  = key.ljust(length, 0.chr)

      k_ipad = key ^ ''.ljust(length, 54.chr)
      k_opad = key ^ ''.ljust(length, 92.chr)

      Digest::SHA1.hexdigest(k_opad + [Digest::SHA1.hexdigest(k_ipad + data)].pack("H*"))
    end
  end

  class UnknownBankError < Exception; end
  class UnknownEnvError < Exception; end
end
