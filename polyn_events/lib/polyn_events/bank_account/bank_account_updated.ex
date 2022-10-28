defmodule BankAccountUpdated do
  @derive Jason.Encoder
  defstruct [:account_number, :amount]
end
