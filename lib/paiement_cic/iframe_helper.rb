module PaiementCic::IframeHelper

  require 'open-uri'

  def paiement_cic_iframe_tag(reference, price, options = {})

    oMac = PaiementCic::TPE.new(options)
    oa = oMac.attributes(reference, price, options)
    chaineMAC = oMac.compute_hmac_sha1(oa.values.join('*'))

    url_retour      = options[:url_retour]
    url_retour_ok   = options[:url_retour_ok]
    url_retour_err  = options[:url_retour_err]

    iframe_params = oa.attributes.merge({
      mode_affichage: "iframe",
      url_retour: options[:url_retour],
      url_retour_err: options[:url_retour_err],
      url_retour_ok: options[:url_retour_ok]
    })

    iframe_url = PaiementCic.default_config.target_url + "?" + iframe_params.map{|k,v| "#{k}=#{URI::encode(v)}"}.join("&")
    content_tag :iframe, src: iframe_url
  end

end