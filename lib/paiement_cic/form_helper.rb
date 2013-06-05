module PaiementCic::FormHelper
  def paiement_cic_hidden_fields(reference, price, options = {})
    oMac = PaiementCic::TPE.new(options)
    oa = oMac.config(reference, price, options)

    chaineMAC = oMac.computeHMACSHA1(oa.values.join('*'))

    url_retour      = options[:url_retour]
    url_retour_ok   = options[:url_retour_ok]
    url_retour_err  = options[:url_retour_err]

    html = hidden_field_tag('MAC', chaineMAC)
    html << hidden_field_tag('url_retour', url_retour)
    html << hidden_field_tag('url_retour_ok', url_retour_ok)
    html << hidden_field_tag('url_retour_err', url_retour_err)

    oa.each do |k,v|
      html << hidden_field_tag(k, v) unless v.empty?
    end

    html
  end
end
