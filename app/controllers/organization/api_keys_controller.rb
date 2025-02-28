class Organization::ApiKeysController < Organization::BaseController
  def index
  end

  def create
    p = SecureRandom.base64(54)
    a = Api::Key.create! api_key_params.merge({password: p})
    redirect_back fallback_location: organization_api_keys_path, flash: {"#{a.id}_api_key": p}
  end

  def destroy
    Api::Key.find_by(id: params[:id]).destroy!
    redirect_back fallback_location: organization_api_keys_path
  end

  private

  def api_key_params
    params.require(:api_key).permit(:id, :name)
  end
end
