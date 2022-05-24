module ValidateCOA
require 'httparty'
require 'nokogiri'

def self.get_response(chart_string)
  HTTParty.post('https://apis-qa.berkeley.edu/coa',query: {'COA' => chart_string},
  #  headers: {'app_id' => @app_id ,'app_key' => @app_key, 'content-type' => 'application/xml'}
    headers: {'app_id' => ENV['COA_APP_ID'] ,'app_key' => ENV['COA_APP_KEY'], 'content-type' => 'application/xml'}
  )
end

def self.get_status(chart_string)
  results = get_response(chart_string)
  xml = Nokogiri::XML(results.to_s) 
  xml.xpath("//ValidateCOAResponse/UC_COA_CHK/COA/StatusText1").text
end

#@app_id = '6debf8ae'
#@app_key =  '20e083c2336f047476040f73bc3d2111'

end
