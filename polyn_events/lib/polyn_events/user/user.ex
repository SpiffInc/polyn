defmodule User do
  @derive Jason.Encoder
  defstruct [:id, :email, :name]

  def execute(%User{id: nil}, %CreateUser{} = command) do
    %{id: id, name: name, email: email} = command

    event = %UserCreated{id: id, name: name, email: email}

    {:ok, event}
  end

  def execute(%User{}, %CreateUser{}) do
    {:error, :user_already_exists}
  end

  def apply(%User{} = user, %UserCreated{} = event) do
    %{id: id, name: name, email: email} = event

    %User{user | id: id, name: name, email: email}
  end
end
