defmodule BankRouter do
  use Commanded.Commands.Router

  dispatch(OpenBankAccount, to: BankAccount, identity: :account_number)
  dispatch(IncrementBalance, to: BankAccount, identity: :account_number)
end
