class Config < ApplicationRecord
  include Organization::Keyable

  before_create :check_for_existing
  before_destroy :check_for_existing
  self.table_name = "configurations"
  broadcasts_refreshes

  serialize :extensions, type: Array, coder: SymbolJSON

  has_secure_password

  store :smtp, accessors: [:server, :port, :username, :password, :box, :domain], prefix: true

  before_save do
    self.email = email.downcase
  end

  validate do |c|
    if !Array.wrap(c.extensions).try(:all?, ->(e) { e.is_a? Symbol })
      errors.add :extensions, :invalid_type, message: "does not decode to an Array of Symbols"
    end
  end

  after_save_commit do
    if oidc_key.blank?
      update!(oidc_key: OpenSSL::PKey::RSA.new(2048))
    end
    begin
      Doorkeeper::OpenidConnect.configuration.instance_variable_set(:@signing_key, oidc_key)
    rescue Doorkeeper::OpenidConnect::Errors::MissingConfiguration
      Rails.logger.info "config: openid connect not initialized yet, not setting @signing_key"
    end
  end

  after_initialize do
    update!(oidc_key: Rails.application.credentials&.oidc&.[](:key).presence ||
    oidc_key.presence ||
    OpenSSL::PKey::RSA.new(2048))
  end

  after_save_commit do
    hash = {}
    (extensions || []).each do |e|
      hash[e] = e.to_s
    end
    Extension.enum :name, hash, instance_methods: false, validate: {allow_nil: true} unless try(:extensions).blank?
  end

  def self.extensions_enum
    hash = {}
    (try(:extensions) || []).each do |e|
      hash[e] = e.to_s
    end
    hash
  end

  class << self
    Config.connection
    Config.column_names.each do |k|
      delegate k, to: :first, allow_nil: true
    end

    delegate :cache_key_with_version, to: :first, allow_nil: true
  end

  private

  def check_for_existing
    raise ActiveRecord::RecordInvalid if Config.count >= 1
  end
end
