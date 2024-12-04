Mox.defmock(Algora.GithubMock, for: Algora.Github.Behaviour)
Application.put_env(:algora, :github_client, Algora.GithubMock)

Mox.defmock(Algora.StripeMock, for: Algora.Stripe.Behaviour)
Application.put_env(:algora, :stripe_impl, Algora.StripeMock)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Algora.Repo, :manual)
