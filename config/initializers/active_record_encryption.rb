# frozen_string_literal: true

# Application-level encryption for sensitive personal data (LGPD).
# Keys come from Rails credentials or from environment variables (production,
# CI, ephemeral environments without a master.key).
primary_key = ENV["AR_ENCRYPTION_PRIMARY_KEY"] || Rails.application.credentials.dig(:active_record_encryption, :primary_key)
deterministic_key = ENV["AR_ENCRYPTION_DETERMINISTIC_KEY"] || Rails.application.credentials.dig(:active_record_encryption, :deterministic_key)
key_derivation_salt = ENV["AR_ENCRYPTION_KEY_DERIVATION_SALT"] || Rails.application.credentials.dig(:active_record_encryption, :key_derivation_salt)

if primary_key && deterministic_key && key_derivation_salt
  Rails.application.configure do
    config.active_record.encryption.primary_key = primary_key
    config.active_record.encryption.deterministic_key = deterministic_key
    config.active_record.encryption.key_derivation_salt = key_derivation_salt
  end
else
  message = [
    "active_record_encryption credentials or AR_ENCRYPTION_* env vars are missing.",
    "Run `bin/rails credentials:edit` and add active_record_encryption: { primary_key, deterministic_key, key_derivation_salt }."
  ].join(" ")
  Rails.logger.warn(message)
  Rails.logger.warn("Falling back to generated in-memory keys — encrypted data will NOT be portable across restarts.")
  Rails.application.configure do
    config.active_record.encryption.primary_key = ActiveSupport::EncryptedFile.generate_key
    config.active_record.encryption.deterministic_key = ActiveSupport::EncryptedFile.generate_key
    config.active_record.encryption.key_derivation_salt = ActiveSupport::EncryptedFile.generate_key
  end
end
