# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.

# PII/LGPD fields and health anamnesis answers must never reach the logs.
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  # personal data
  :cpf, :rg_user, :address, :cep, :district, :phone_number, :birthdate,
  :ufrn_registration_number, :email,
  # health/safety answers (PAR-Q style)
  :heart_problem, :chest_pain, :recent_chest_pain, :dizziness, :bone_problem,
  :blood_pressure_meds, :other_reasons, :physical_activity_responsibility,
  :terms_accepted
]
