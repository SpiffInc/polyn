defmodule UserCreated do
  @derive Jason.Encoder
  defstruct [:id, :name, :email]
end
