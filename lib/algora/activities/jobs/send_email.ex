defmodule Algora.Activities.SendEmail do
  @moduledoc false
  use Oban.Worker,
    queue: :background,
    max_attempts: 1,
    tags: ["email", "activities"]

  alias Swoosh.Email

  @from_name "Algora"
  @from_email "info@algora.io"

  # unique: [period: 30]

  def changeset(attrs) do
    new(attrs)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    case args do
      %{"email" => email, "name" => name, "title" => subject, "body" => body} ->
        email =
          Email.new()
          |> Email.to({name, email})
          |> Email.from({@from_name, @from_email})
          |> Email.subject(subject)
          |> Email.text_body(body)

        Algora.Mailer.deliver(email)

      _args ->
        :discard
    end
  end
end
