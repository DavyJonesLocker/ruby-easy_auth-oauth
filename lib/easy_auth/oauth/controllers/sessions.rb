module EasyAuth::Oauth::Controllers::Sessions

  private

  def after_successful_sign_in_with_oauth(identity)
    send("after_successful_sign_in_with_oauth_for_#{params[:provider]}", identity)
  end

  def after_successful_sign_in_url_with_oauth(identity)
    send("after_successful_sign_in_url_with_oauth_for_#{params[:provider]}", identity)
  end

  def after_failed_sign_in_with_oauth(identity)
    send("after_failed_sign_in_with_oauth_for_#{params[:provider]}", identity)
  end
end
