module Adyen::TestCards
  VISA = {
    expiry_month: '08',
    expiry_year: '2018',
    holder_name: 'Testy McTesterson',
    number: '4111111111111111',
    cvc: '737',
  }

  MASTERCARD_3DSECURE = {
    expiry_month: '08',
    expiry_year: '2018',
    holder_name: 'Testy McTesterson',
    number: '5212345678901234',
    cvc: '737',

    username: 'user',
    password: 'password',
  }
end
