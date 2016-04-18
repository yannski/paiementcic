require 'digest/sha1'

module PaiementCic
  class TPE
    attr_accessor :default_config

    attr_accessor :hmac_key, :tpe, :societe, :mail, :url_retour, :url_retour_ok, :url_retour_err

    attr_writer :target_url

    def initialize(options = {}, &block)
      self.default_config = PaiementCic.default_config
      if block_given?
        configure(&block)
      else
        [:hmac_key, :tpe, :societe, :mail, :url_retour, :url_retour_ok, :url_retour_err].each{|attribute|
          send("#{attribute}=", options[attribute] || default_config.send(attribute))
        }

        [:target_url, :bank, :env].each{|attribute|
          send("#{attribute}=", options[attribute]) if options[attribute]
        }
      end
    end

    ["bank", "env"].each do |m|
      define_method(m) { instance_variable_get("@#{m}") || Object.const_get("PaiementCic::"+("default_#{m}".upcase))}
      define_method "#{m}=" do |value|
        raise Object.const_get("Unknown#{m.capitalize}Error") unless END_POINTS.select{|k,v| k == value.to_sym or v.include?(value.to_sym)}.any?
        instance_variable_set("@#{m}", value)
      end
    end

    def configure(&block)
      yield self
    end

    def target_url
      @target_url || begin
        if self.bank && self.env
          END_POINTS[self.bank][self.env]
        else
          default_config.target_url
        end
      end
    end

    def attributes_for_form(reference, amount_in_cents, options = {})
      {
        'TPE' => (options[:tpe] || tpe),
        'date' => Time.now.strftime(PaiementCic::DATE_FORMAT),
        'montant' => ("%.2f" % amount_in_cents) + "EUR",
        'reference' => reference.to_s,
        'texte-libre' => '',
        'version' => PaiementCic::API_VERSION,
        'lgue' => 'FR',
        'societe' => (options[:societe] || societe),
        'mail' => (options[:mail] || mail),
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
        tpe, params['date'], params['montant'], params['reference'], params['texte-libre'], PaiementCic::API_VERSION, params['lgue'], params["societe"],
        params["mail"], params["nbrech"], params["dateech1"], params["montantech1"], params["dateech2"], params["montantech2"], params["dateech3"], params["montantech3"],
        params["dateech4"], params["montantech4"]
      ].join('*') + "*"
    end

    def cic_mac_string params
      [
        tpe, params['date'], params['montant'], params['reference'], params['texte-libre'], PaiementCic::API_VERSION, params['code-retour'], params["cvx"],
        params["vld"], params["brand"], params["status3ds"], params["numauto"], params["motifrefus"], params["originecb"], params["bincb"], params["hpancb"],
        params["ipclient"], params["originetr"], params["veres"], params["pares"]
      ].join('*') + "*"
    end

    def verify_hmac params
      params.has_key?('MAC') && valid_hmac?(cic_mac_string(params), params['MAC'])
    end

    # Check if the HMAC matches the HMAC of the data string
    def valid_hmac?(mac_string, sent_mac)
      compute_hmac_sha1(mac_string) == sent_mac.downcase
    end

    # Return the HMAC for a data string
    def compute_hmac_sha1(data)
      hmac_sha1(usable_key, data).downcase
    end
    alias_method :computeHMACSHA1, :compute_hmac_sha1

    # Public: Diagnose result from returned params
    #
    # params - The hash of params returned by the bank.
    #
    # Returns a hash { :status => :error | :success | :canceled | :bad_params,
    #                  :user_msg => "msg for user",
    #                  :tech_msg => "msg for back-office" }
    def self.diagnose(params)
      if params['code-retour'].blank?
        { :status => :bad_params,
          :user_msg => 'Vous allez être redirigé vers la page d’accueil',
          :tech_msg => 'La reference est vide. Suspicion de tentative de fraude.' }
      #elsif !valid_signature?(params)
      #  { :status => :bad_params,
      #    :user_msg => 'Vous allez être redirigé vers la page d’accueil',
      #    :tech_msg => 'La signature ne correspond pas. Suspicion de tentative de fraude.' }
      else case params['code-retour']
        when 'payetest'
          { :status => :success,
            :user_msg => 'Votre paiement de test a été accepté par la banque.',
            :tech_msg => "Paiement de test accepté." }
        when 'paiement'
          { :status => :success,
            :user_msg => 'Votre paiement a été accepté par la banque.',
            :tech_msg => "Paiement accepté." }
        #when '02'
        #  { :status => :error,
        #    :user_msg => 'Nous devons entrer en relation avec votre banque avant d’obtenir confirmation du paiement.',
        #    :tech_msg => 'Le commerçant doit contacter la banque du porteur.' }
        when 'Annulation'
          { :status => :error,
            :user_msg => 'Le paiement a été refusé par la banque.',
            :tech_msg => "Paiement refusé par la banque. Motif : #{params[:motifrefus]}" }
        #when '17'
        #  { :status => :canceled,
        #    :user_msg => 'Vous avez annulé votre paiement.',
        #    :tech_msg => 'Paiement annulé par le client.' }
        #when '30'
        #  { :status => :bad_params,
        #    :user_msg => 'En raison d’une erreur technique, le paiement n’a pu être validé.',
        #    :tech_msg => "Erreur de format dans la requête (champ #{VADS_QUERY_FORMAT_ERROR[params[:vads_extra_result]]}). Signaler au développeur." }
        #when '96'
        #  { :status => :bad_params,
        #    :user_msg => 'En raison d’une erreur technique, le paiement n’a pu être validé.',
        #    :tech_msg => 'Code vads_result inconnu. Signaler au développeur.' }
        else
          { :status => :bad_params,
            :user_msg => 'En raison d’une erreur technique, le paiement n’a pu être validé.',
            :tech_msg => 'Code retour inconnu. Signaler au développeur.' }
        end
      end
    end

    private

    # Return the key to be used in the hmac function
    def usable_key
      hex_string_key  = hmac_key[0..37]
      hex_final   = hmac_key[38..40] + "00";

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

    def hmac_sha1(key, data)
      length = 64

      if (key.length > length)
        key = [Digest::SHA1.hexdigest(key)].pack("H*")
      end

      key = key.ljust(length, 0.chr)

      k_ipad = key ^ ''.ljust(length, 54.chr)
      k_opad = key ^ ''.ljust(length, 92.chr)

      Digest::SHA1.hexdigest(k_opad + [Digest::SHA1.hexdigest(k_ipad + data)].pack("H*"))
    end
  end
end
