Mox.defmock(Algora.Github.MockClient, for: Algora.Github.Behaviour)
Application.put_env(:algora, :github_client, Algora.Github.MockClient)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Algora.Repo, :manual)
