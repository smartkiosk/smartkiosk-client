class Application
  get '/session_records' do
    json SessionRecord.recent.as_json(
      :only => [ :started_at, :upstream, :downstream, :time ]
    )
  end
end