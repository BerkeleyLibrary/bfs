module ValidateCOA
require 'httparty'
require 'nokogiri'

USER_AGENT = 'validate_coa https://git.lib.berkeley.edu/lap/BFS'

def self.get_response(chart_string)
  #HTTParty.post('https://apis.berkeley.edu/coa',query: {'COA' => chart_string},
  HTTParty.post('https://gateway.api.berkeley.edu/coa',query: {'COA' => chart_string},
    headers: {'User_Agent' => USER_AGENT, 'Accept' => 'application/xml', 'app_id' => ENV['COA_APP_ID'] ,'app_key' => ENV['COA_APP_KEY'], 'content-type' => 'application/xml'}
  )
end

def self.get_status(chart_string)
  results = get_response(chart_string)
  xml = Nokogiri::XML(results.to_s) 
  xml.xpath("//ValidateCOAResponse/UC_COA_CHK/COA/StatusText1").text
end


end
