# TrustIn

Hi and welcome to TrustIn. We are a small company located in Paris. We help financial departments to
assess their suppliers database reliability by performing an evaluation on the supplier's company.

Unfortunately, our evaluations don't hold the same relevance depending on their state. We have a system
in place which lists the state of the evaluations performed for a specific type of
company (i.e SIREN). Your task is to add a new feature to our system so that we can evaluate
a new company registration (i.e VAT -tax number-).

First an introduction to our system:
 - All evaluations have a type which refers to the company registration's type
 - All evaluations have a durability which denotes the evaluation's relevance and validity
 - All evaluations have a state and its reason

Now it gets a little bit tricky with the following rules:

 - When the durability is equal or greater than 50 and the state is unconfirmed because the api is unreachable, the SIREN evaluation's durability decreases of 5 points;
 - When the durability is lower than 50 and the state is unconfirmed because the api is unreachable, the SIREN evaluation's durability decreases of 1 point;

We recently signed up a new client. His database is filled with VAT company registrations. This requires an update in our system:

 - When the durability is equal or greater than 50 and the state is unconfirmed because the api is unreachable, the VAT evaluation's durability decreases of 1 point;
 - When the durability is lower than 50 and the state is unconfirmed because the api is unreachable, the VAT evaluation's durability decreases of 3 points;

 Some rules apply to both company registration types:
 - When the durability is greater than 0 and the state is unconfirmed for an ongoing api database update, a new evaluation is done;
 - When the durability is greater than 0 and the state is favorable, the company registration evaluation's durability decreases of 1 point;
 - The durability cannot go below 0;
 - The durability does not decrease if the company registration evaluation's state is unfavorable;
 - When the durability is equal to 0, a new evaluation is done;


 The VAT evaluation logic to use is the following (e.g. fake API):
 ```ruby
      data = [
        { state: "favorable", reason: "company_opened" },
        { state: "unfavorable", reason: "company_closed" },
        { state: "unconfirmed", reason: "unable_to_reach_api" },
        { state: "unconfirmed", reason: "ongoing_database_update" },
      ].sample
      evaluation.state = data[:state]
      evaluation.reason = data[:reason]
      evaluation.durability = 100
 ```

Here are some examples of VAT numbers: `IE6388047V`, `LU26375245`, `GB727255821`


Feel free to make any changes to the #update_durability method and add any new code as long as everything
still works correctly and do not forget to add/rework the specs.

Good luck and may the force be with you!
