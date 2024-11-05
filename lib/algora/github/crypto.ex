defmodule Algora.Github.Crypto do
  alias Joken
  alias Algora.Github

  @doc """
  Generates a JWT (JSON Web Token) for GitHub App authentication.

  ## Returns

  `{:ok, jwt, claims}` on success, `{:error, reason}` on failure
  """
  @spec generate_jwt() :: {:ok, String.t(), map()} | {:error, any()}
  def generate_jwt() do
    payload = %{
      "iat" => System.system_time(:second),
      "exp" => System.system_time(:second) + 600,
      "iss" => Github.client_id()
    }

    signer = Joken.Signer.create("RS256", %{"pem" => Github.private_key()})

    Joken.generate_and_sign(%{}, payload, signer)
  end
end
