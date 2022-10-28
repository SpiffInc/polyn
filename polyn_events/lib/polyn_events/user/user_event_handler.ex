defmodule UserEventHandler do
  use Commanded.Event.Handler,
    application: PolynEvents.Application,
    name: __MODULE__

  def handle(%UserCreated{}, _metadata) do
    # ... process the event
    :ok
  end
end
