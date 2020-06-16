require 'esign/errors'
require 'net/http'
require 'uri'
require 'byebug'

module Esign
  module Request
    extend self

    def post_to_identity_with_token!(url, payload, headers={}, retry_times = 0)
      retrieve_identity_token
      
      headers = headers.merge(
        {
          'Content-Type' => 'application/json',
          'X-Tsign-Open-App-Id' => app_id,
          'X-Tsign-Open-Token' => @identity_token_info['token']
        }
      )

      resp = post(url, payload.to_json, headers)

      if resp.instance_of?(Net::HTTPUnauthorized)
        raise Errors::Unauthorized
      end
      
      JSON.parse resp.body
    rescue Errors::Unauthorized
      post_to_identity_with_token(url, payload, headers, retry_times + 1) if retry_times < 2
    end

    def post_json(url, payload, headers=json_headers)
      resp = post(url, payload, headers)
      JSON.parse resp.body
    end

    def post(url, payload, headers)
      uri = URI.parse(url)

      Net::HTTP.post(
        uri,
        payload,
        headers
      )
    end

    def post_multipart(url, form_data)
      uri = URI(url)
      https = Net::HTTP.new(uri.host, uri.port);

      req = Net::HTTP::Post.new(uri)
      req.set_form(form_data, 'multipart/form-data')
      resp = https.request(req)

      JSON.parse(resp.body)
    end

    def get(url)
      uri = URI.parse url
      Net::HTTP.get(uri)
    end

    # 获取易签宝认证服务token
    # token有效时长为120分钟。如果有多台机器建议使用分布式存储，新旧token会共存5分钟。
    # token_info: { 'refreshToken' => 'xx', 'token' => 'xxx', 'expiresIn' => 'xxx' }
    def retrieve_identity_token
      return if @identity_token_info && @identity_token_info['expiresIn'].to_i > Time.now.to_i * 1000

      response = get(identity_token_url)
      @identity_token_info = JSON.parse(response)['data']
    end

    def identity_host
      Esign.configuration.identity_host
    end

    def identity_token_url
      "https://#{identity_host}/v1/oauth2/access_token?appId=#{app_id}&&secret=#{app_secret}&&grantType=client_credentials"
    end

    def app_id
      Esign.configuration.app_id
    end

    def app_secret
      Esign.configuration.app_secret
    end

    def json_headers
      {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
    end
  end
end
