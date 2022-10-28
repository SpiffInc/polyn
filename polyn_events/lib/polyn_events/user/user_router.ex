defmodule UserRouter do
  use Commanded.Commands.Router

  identify(User, by: :id, prefix: "user-")
  dispatch([CreateUser], to: User)
end
