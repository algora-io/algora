Mox.defmock(Algora.GithubMock, for: Algora.Github.Behaviour)
Application.put_env(:algora, :github_client, Algora.GithubMock)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Algora.Repo, :manual)
