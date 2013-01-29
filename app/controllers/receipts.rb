class Application
  get '/receipts' do
    Receipt.recent.includes(:document).to_json(
      :only => [:id, :printer, :keyword, :created_at, :printed], :methods => :document_title
    )
  end

  post '/receipts/print' do
    receipts = Receipt.where(:printed => false)
    receipts.each{|x| x.print}
    receipts.to_json(:only => [:id, :printed])
  end
end