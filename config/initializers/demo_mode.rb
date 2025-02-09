# frozen_string_literal: true

# See README at https://github.com/Betterment/demo_mode

if Rails.env.demo?
  Rails.application.config.after_initialize do
    if ActiveRecord::Base.connection.table_exists?("configurations") &&
        ActiveRecord::Base.connection.table_exists?("sessions") &&
        ActiveRecord::Base.connection.table_exists?("members")
      Config.delete_all
      Config.create!(FactoryBot.attributes_for(:config))
      Member.delete_all
      ActiveRecord::SessionStore::Session.destroy_all

      DemoMode.configure do
        current_user_method :current_user

        splash_base_controller_name "My::Journey::BaseController"

        app_base_controller_name "ApplicationController"

        password { "correct-horse-battery-staple" }

        icon "demo_mode/icon--user.png"
      end
    end
  end
end
