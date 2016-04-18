module PaiementCic::FormHelper
  def paiement_cic_hidden_fields(paiement_cic_tpe, reference, price, options = {})
    hsh = paiement_cic_tpe.attributes_for_form(reference, price, options)

    url_retour     = options[:url_retour]     || paiement_cic_tpe.url_retour
    url_retour_ok  = options[:url_retour_ok]  || paiement_cic_tpe.url_retour_ok
    url_retour_err = options[:url_retour_err] || paiement_cic_tpe.url_retour_err

    mac = paiement_cic_tpe.compute_hmac_sha1(hsh.values.join('*'))

    html = hidden_field_tag('MAC', mac)
    html << hidden_field_tag('url_retour', url_retour)
    html << hidden_field_tag('url_retour_ok', url_retour_ok)
    html << hidden_field_tag('url_retour_err', url_retour_err)

    hsh.each do |k,v|
      html << hidden_field_tag(k, v) unless v.empty?
    end

    html
  end
end
