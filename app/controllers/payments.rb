class Application
  post '/payments' do
    payment = Payment.create! params[:payment]
    json (payment.check ? payment.as_json : false)
  end

  post '/payments/:id/open' do
    payment = Payment.find(params[:id])
    Smartware.cash_acceptor.open(payment.limit.try('[]', :min), payment.limit.try('[]', :max))
    json (Smartware.cash_acceptor.error.blank? ? true : false)
  end

  post '/payments/:id/pay' do
    payment = Payment.find(params[:id])
    Smartware.cash_acceptor.close
    payment.update_attributes(
      :banknotes => Smartware.cash_acceptor.banknotes,
      :payment_type => params['payment']['payment_type']
    )
    payment.receipt.print
    payment.pay
    nil
  end

  get '/payments/cash' do
    json Smartware.cash_acceptor.sum.to_json
  end

  get '/payments/reset' do
    Smartware.cash_acceptor.close
    nil
  end
end