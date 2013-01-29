class Application
  post '/collections' do
    if collection = Collection.collect!
      collection.report
      collection.receipt.print
    end

    json collection
  end
end