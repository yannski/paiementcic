module PaiementCic::FormHelper
  require 'open-uri'

  def paiement_cic_hidden_fields(reference, price, options = {})
    oMac = PaiementCic::TPE.new(options)
    oa = oMac.attributes(reference, price, options)

    chaineMAC = oMac.compute_hmac_sha1(oa.values.join('*'))     

    url_retour      = config.url_retour
    url_retour_ok   = config.url_retour_ok
    url_retour_err  = config.url_retour_err

    html = hidden_field_tag('MAC', chaineMAC)
    html << hidden_field_tag('url_retour', url_retour)
    html << hidden_field_tag('url_retour_ok', url_retour_ok)
    html << hidden_field_tag('url_retour_err', url_retour_err)

    oa.each do |k,v|
      html << hidden_field_tag(k, v) unless v.empty?
    end

    html
  end

  def paiement_cic_iframe_url(reference, price, options = {})

    oMac = PaiementCic::TPE.new(options)
    oa = oMac.attributes(reference, price, options)
    chaineMAC = oMac.compute_hmac_sha1(oMac.mac_string(oa))
    iframe_params = oa.merge({
      mode_affichage: "iframe",
      "MAC" => chaineMAC
    }).merge(options).reject{|k, v| v.blank?}

    [PaiementCic.default_config.target_url,"?",iframe_params.map{|k,v| "#{k}=#{CGI::escape(v)}"}.join("&")].join
  end

end
