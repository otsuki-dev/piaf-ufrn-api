# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("PIAF_MAILER_FROM", "PIAF COESPE/UFRN <piaf@coespe.ufrn.br>")
  layout "mailer"
end
