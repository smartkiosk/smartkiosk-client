class Application
  post '/payments' do
    payment = Payment.create! params[:payment]

    json (payment.check ? payment.as_json : false)
  end

  post '/payments/:id/open_cash_acceptor' do
    payment = Payment.find(params[:id])
    min = nil
    max = nil

    if payment.limit && payment.limit.include?(:min)
      min = payment.limit[:min].to_i
      max = payment.limit[:max].to_i
    end

    Smartware.cash_acceptor.open min, max

    json Smartware.cash_acceptor.error.blank?
  end

  post '/payments/close_cash_acceptor' do
    Smartware.cash_acceptor.close
    nil
  end

  post '/payments/open_card_reader' do
    Smartware.card_reader.open

    json Smartware.card_reader.error.blank?
  end

  post '/payments/close_card_reader' do
    Smartware.card_reader.close
    nil
  end

  post '/payments/:id/pay' do
    payment = Payment.find(params[:id])
    Smartware.cash_acceptor.close

    if payment.payment_type == 0
      attributes = {
        :banknotes => Smartware.cash_acceptor.banknotes
      }
    else
      attributes = {
        :paid_amount => params['payment']['paid_amount'],
        :card_track1 => params['payment']['card_track1'],
        :card_track2 => params['payment']['card_track2']
      }
    end

    attributes[:meta] = params['payment']['meta']

    payment.update_attributes attributes
    payment.receipt.print
    payment.pay
    nil
  end
end