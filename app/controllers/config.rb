class Application
  def configs
    @configs ||= {
      :application => Terminal.config,
      :smartware => Smartkiosk::Config::YAML.new(Application.root.join 'config/services/smartware.yml')
    }
  end

  get '/config' do
    json Hash[*configs.map{|k,v| [k, v.marshal_dump]}.flatten]
  end

  post '/config' do
    params[:smartware][:interfaces] = params[:smartware][:interfaces].values

    configs.each do |key, value|
      value.marshal_load params[key].to_hash_recursive unless params[key].blank?
      value.save!
    end

    json Hash[*configs.map{|k,v| [k, v.marshal_dump]}.flatten]
  end
end