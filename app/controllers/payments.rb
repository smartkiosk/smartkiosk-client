class Application
  post '/payments' do
    payment = Payment.create! params[:payment]
    (payment.check ? payment.as_json : false).to_json
  end

  post '/payments/open/:id' do
    payment = Payment.find(params[:id])
    Smartware.cash_acceptor.open(payment.limit.try('[]', :min), payment.limit.try('[]', :max))
    (Smartware.cash_acceptor.error.blank? ? true : false).to_json
  end

  post '/payments/pay/:id' do
    payment = Payment.find(params[:id])
    Smartware.cash_acceptor.close
    payment.update_attributes :banknotes => Smartware.cash_acceptor.banknotes
    payment.receipt.print
    payment.pay
    ""
  end

  get '/payments/cash' do
    Smartware.cash_acceptor.sum.to_json
  end

  get '/payments/reset' do
    Smartware.cash_acceptor.close
    ""
  end
end