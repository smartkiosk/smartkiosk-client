class Application
  get '/receipts' do
    json Receipt.recent.includes(:document).as_json(
      :only => [:id, :printer, :keyword, :created_at, :printed], :methods => :document_title
    )
  end

  post '/receipts/print' do
    receipts = Receipt.where(:printed => false)
    receipts.each{|x| x.print}
    json receipts.as_json(:only => [:id, :printed])
  end
end