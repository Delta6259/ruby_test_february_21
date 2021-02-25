require "json"
require "net/http"

class TrustIn
  def initialize(evaluations)
    @evaluations = evaluations
  end

  def update_durability()
    @evaluations.each do |evaluation|
      if evaluation.type == "SIREN"
        if evaluation.durability > 0 && evaluation.state == "unconfirmed" && evaluation.reason == "ongoing_database_update"
          uri = URI("https://public.opendatasoft.com/api/records/1.0/search/?dataset=sirene_v3" \
            "&q=#{evaluation.value}&sort=datederniertraitementetablissement" \
            "&refine.etablissementsiege=oui")
          response = Net::HTTP.get(uri)
          parsed_response = JSON.parse(response)
          company_state = parsed_response["records"].first["fields"]["etatadministratifetablissement"]
          if company_state == "Actif"
            evaluation.state = "favorable"
            evaluation.reason = "company_opened"
            evaluation.durability = 100
          else
            evaluation.state = "unfavorable"
            evaluation.reason = "company_closed"
            evaluation.durability = 100
          end
        elsif evaluation.durability >= 50
          unless evaluation.state == "unfavorable"
            if evaluation.state == "unconfirmed" && evaluation.reason == "unable_to_reach_api"
              if evaluation.durability > 0
                evaluation.durability = evaluation.durability - 5
              end
            elsif evaluation.state == "favorable"
              if evaluation.durability > 0
                evaluation.durability = evaluation.durability - 1
              end
            end
          end
        elsif evaluation.durability <= 50 && evaluation.durability > 0
          if evaluation.state == "unconfirmed" && evaluation.reason == "unable_to_reach_api" || evaluation.state == "favorable"
            if evaluation.durability > 0
              evaluation.durability = evaluation.durability - 1
            end
          end
        else
          if evaluation.state == "favorable" || evaluation.state == "unconfirmed"
            uri = URI("https://public.opendatasoft.com/api/records/1.0/search/?dataset=sirene_v3" \
                      "&q=#{evaluation.value}&sort=datederniertraitementetablissement" \
                      "&refine.etablissementsiege=oui")
            response = Net::HTTP.get(uri)
            parsed_response = JSON.parse(response)
            company_state = parsed_response["records"].first["fields"]["etatadministratifetablissement"]
            if company_state == "Actif"
              evaluation.state = "favorable"
              evaluation.reason = "company_opened"
              evaluation.durability = 100
            else
              evaluation.state = "unfavorable"
              evaluation.reason = "company_closed"
              evaluation.durability = 100
            end
          end
        end
      end
    end
  end
end

class Evaluation
  attr_accessor :type, :value, :durability, :state, :reason

  def initialize(type:, value:, durability:, state:, reason:)
    @type = type
    @value = value
    @durability = durability
    @state = state
    @reason = reason
  end

  def to_s()
    "#{@type}, #{@value}, #{@durability}, #{@state}, #{@reason}"
  end
end
