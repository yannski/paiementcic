require 'paiement_cic/form_helper'

module PaiementCic
  class Railtie < Rails::Railtie
    initializer "paiement_cic.form_helpers" { ActionView::Base.send :include, FormHelper }
    initializer "paiement_cic.iframe_helpers" { ActionView::Base.send :include, IframeHelper }
  end
end
