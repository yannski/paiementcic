module PaiementCic
  class TPE
    attr_accessor :config

    def initialize(options = nil)
      self.config = options.nil? ? PaiementCic.default_config :
        PaiementCic::Config.new(options)
    end

    def attributes(reference, amount_in_cents, options = {})
      {
        'TPE' => config.tpe,
        'date' => Time.now.strftime(PaiementCic::DATE_FORMAT),
        'montant' => ("%.2f" % amount_in_cents) + "EUR",
        'reference' => reference.to_s,
        'texte-libre' => '',
        'version' => PaiementCic::API_VERSION,
        'lgue' => 'FR',
        'societe' => config.societe,
        'mail' => options[:mail].to_s,
        'nbrech' => options[:nbrech].to_s,
        'dateech1' => options[:dateech1].to_s,
        'montantech1' => options[:montantech1].to_s,
        'dateech2' => options[:dateech2].to_s,
        'montantech2' => options[:montantech2].to_s,
        'dateech3' => options[:dateech3].to_s,
        'montantech3' => options[:montantech3].to_s,
        'dateech4' => options[:dateech4].to_s,
        'montantech4' => options[:montantech4].to_s,
        'options' => options[:options].to_s
      }
    end

    def mac_string params
      [
        config.tpe, params['date'], params['montant'], params['reference'], params['texte-libre'],
        PaiementCic::API_VERSION, params['code-retour'], params['cvx'], params['vld'], params['brand'],
        params['status3ds'], params['numauto'], params['motifrefus'], params['originecb'],
        params['bincb'], params['hpancb'], params['ipclient'], params['originetr'],
        params['veres'], params['pares']
      ].join('*') + "*"
    end

    def verify_hmac params
      params.has_key?('MAC') && valid_hmac?(mac_string(params), params['MAC'])
    end

    # Check if the HMAC matches the HMAC of the data string
    def valid_hmac?(mac_string, sent_mac)
      compute_hmac_sha1(mac_string) == sent_mac.downcase
    end

    # Return the HMAC for a data string
    def compute_hmac_sha1(data)
      PaiementCic.hmac_sha1(usable_key, data).downcase
    end
    alias_method :computeHMACSHA1, :compute_hmac_sha1

    private
    # Return the key to be used in the hmac function
    def usable_key

      hex_string_key  = config.hmac_key[0..37]
      hex_final   = config.hmac_key[38..40] + "00";

      cca0 = hex_final[0].ord

      if cca0 > 70 && cca0 < 97
        hex_string_key += (cca0 - 23).chr + hex_final[1..2]
      elsif hex_final[1..2] == "M"
        hex_string_key += hex_final[0..1] + "0"
      else
        hex_string_key += hex_final[0..2]
      end

      [hex_string_key].pack("H*")
    end
  end
end
