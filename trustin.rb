require "json"
require "net/http"

CONSTANTS = {
  evaluation_types: {
    siren: 'SIREN',
    vat: 'VAT'
  },
  evaluation_states: {
    unconfirmed: 'unconfirmed',
    favorable: 'favorable',
    unfavorable: 'unfavorable'
  },
  evaluation_reasons: {
    unable_to_reach_api: 'unable_to_reach_api',
    ongoing_database_update: 'ongoing_database_update'
  }
}

class TrustIn
  def initialize(evaluations)
    @evaluations = evaluations
  end

  def update_durability()
    @evaluations.each do |evaluation|
      # Must be a switch case statement.

      case evaluation.type
      when CONSTANTS[:evaluation_types][:siren]
        check_siren(evaluation)
      when CONSTANTS[:evaluation_types][:vat]
        check_vat(evaluation)
      else
        raise 'Unknown evaluation type'
      end
    end
  end

  private

  def check_siren(evaluation)
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

  def check_vat(evaluation)
    state, durability, reason = [evaluation.state, evaluation.durability, evaluation.reason]

    return run_vat_evaluation(evaluation) if durability == 0
    return evaluation if state == CONSTANTS[:evaluation_states][:unfavorable]

    if durability >= 50
      if state == CONSTANTS[:evaluation_states][:unconfirmed] && reason == CONSTANTS[:evaluation_reasons][:unable_to_reach_api]
        evaluation.durability -= 1
      end
    else
      if state == CONSTANTS[:evaluation_states][:unconfirmed] && reason == CONSTANTS[:evaluation_reasons][:unable_to_reach_api]
        evaluation.durability -= 3
      end
    end

    if durability > 0
      if state == CONSTANTS[:evaluation_states][:favorable]
        evaluation.durability -= 1
      end
      if state == CONSTANTS[:evaluation_states][:unconfirmed] && reason == CONSTANTS[:evaluation_reasons][:ongoing_database_update]
        run_vat_evaluation(evaluation)
      end
    end
  end

  def run_vat_evaluation(evaluation)
    data = [
      { state: "favorable", reason: "company_opened" },
      { state: "unfavorable", reason: "company_closed" },
      { state: "unconfirmed", reason: "unable_to_reach_api" },
      { state: "unconfirmed", reason: "ongoing_database_update" },
    ].sample
    evaluation.state = data[:state]
    evaluation.reason = data[:reason]
    evaluation.durability = 100
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
