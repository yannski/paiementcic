require 'paiement_cic/form_helper'

module PaiementCic
  class Railtie < Rails::Railtie
    initializer "paiement_cic.form_helpers" do
      ActionView::Base.send :include, FormHelper
      ActionView::Base.send :include, IframeHelper
    end
  end
end
