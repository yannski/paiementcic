require 'overrides/string'

require 'paiement_cic/config'
require 'paiement_cic/tpe'
require 'paiement_cic/railtie' if defined?(Rails)

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

  class UnknownBankError < Exception; end
  class UnknownEnvError < Exception; end
end
