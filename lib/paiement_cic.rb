require 'overrides/string'

require 'paiement_cic/config'
require 'paiement_cic/tpe'
require 'paiement_cic/railtie' if defined?(Rails)

require 'digest/sha1'


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

  def self.default_config
    @@default_config ||= PaiementCic::Config.new
  end

  def self.hmac_sha1(key, data)
    length = 64

    if (key.length > length)
      key = [Digest::SHA1.hexdigest(key)].pack("H*")
    end

    key = key.ljust(length, 0.chr)

    k_ipad = key ^ ''.ljust(length, 54.chr)
    k_opad = key ^ ''.ljust(length, 92.chr)

    Digest::SHA1.hexdigest(k_opad + [Digest::SHA1.hexdigest(k_ipad + data)].pack("H*"))
  end

  class UnknownBankError < Exception; end
  class UnknownEnvError < Exception; end
end
