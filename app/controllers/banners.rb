class Application
  get '/banners' do
    haml :banners
  end

  get '/banners/playlist' do
    banner = Banner.where('playorder > ?', (params[:prev]||0).to_f).first
    banner = Banner.first unless banner
    banner.to_json
  end
end