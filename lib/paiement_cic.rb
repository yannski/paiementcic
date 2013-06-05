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

  class << self
    attr_accessor :hmac_key, :tpe, :societe, :env
    attr_writer :target_url

    def configure(&block)
      yield(self) if block_given?
    end

    def target_url
      @target_url ||= (env == 'production' ? '' : "https://paiement.creditmutuel.fr/test/paiement.cgi") # "https://ssl.paiement.cic-banques.fr/paiement.cgi"
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
end
