require 'rubygems'
require 'patron'
require 'json'

module DevinoSms
  class Client
    attr_accessor :validity

    SMS_SERVER = 'http://rest.devinotele.com/'

    def initialize(login, password)
      @session_id   = session_id(login, password)
      self.validity = 10
    end

    def send(destinationAddress, sourceAddress, message, sendDate = nil)
      query =  build_query({'sendDate'           => sendDate,
                            'destinationAddress' => destinationAddress,
                            'data'               => message,
                            'sourceAddress'      => sourceAddress,
                            'validity'           => validity}, true)

      response = session.post("Sms/Send", query)
      response.status == 200 ? JSON.parse(response.body) : raise(JSON.parse(response.body)['Desc'])
    end

    def state(message_id)
      response = session.get("Sms/State?#{build_query({'messageId' => message_id})}")

      response.status == 200 ? JSON.parse(response.body) : raise(JSON.parse(response.body)['Desc'])
    end

    def balance
      response = session.get("User/Balance?#{build_query}")

      response.status == 200 ? response.body.to_f : raise(JSON.parse(response.body)['Desc'])
    end

    def income(start_date, finish_date)
      response = session.get("Sms/In?#{build_query({'minDateUTC' => start_date,
                                                    'maxDateUTC' => finish_date})}")

      response.status == 200 ? JSON.parse(response.body) : raise(JSON.parse(response.body)['Desc'])
    end

    private

    def build_query(params = {}, escape = true)
      query = Patron::Util.build_query_string_from_hash(params, escape)
      query = "sessionId=#{session_id}&#{query}" if defined?(@session_id)
      query
    end

    def session_id(login = nil, password = nil)
      return @session_id if defined?(@session_id)

      response = session.get("User/SessionId?#{build_query({'login'    => login,
                                                            'password' => password})}")

      response.status == 200 ? response.body.gsub('"', '') : raise(JSON.parse(response.body)['Desc'])
    end

    def session
      return @session if defined?(@session)

      @session = Patron::Session.new
      @session.timeout = 10
      @session.base_url = Client::SMS_SERVER
      @session
    end
  end
end
