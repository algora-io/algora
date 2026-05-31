defmodule Algora.Crypto.CryptoWallet do
  @moduledoc """
  Schema for user-linked crypto wallets.

  Supports non-custodial wallet connections where users link their
  existing wallets (e.g., Phantom, Solflare) to their Algora account.
  The private key never touches the server.
  """

  use Algora.Schema

  @networks [:solana]
  @statuses [:active, :inactive, :verification_pending]

  typed_schema "crypto_wallets" do
    field :address, :string, null: false
    field :network, Ecto.Enum, values: @networks, null: false, default: :solana
    field :status, Ecto.Enum, values: @statuses, null: false, default: :active
    field :label, :string
    field :provider_meta, :map, default: %{}

    belongs_to :user, Algora.Accounts.User, null: false

    timestamps()
  end

  @doc """
  Changeset for creating a new crypto wallet.
  Validates the wallet address format based on the network.
  """
  def changeset(wallet, attrs) do
    wallet
    |> cast(attrs, [:id, :address, :network, :status, :label, :provider_meta, :user_id])
    |> validate_required([:address, :network, :status, :user_id])
    |> validate_address_format()
    |> unique_constraint([:address, :network])
    |> foreign_key_constraint(:user_id)
    |> generate_id()
  end

  @doc """
  Changeset for updating an existing crypto wallet (e.g., status change).
  """
  def update_changeset(wallet, attrs) do
    wallet
    |> cast(attrs, [:status, :label, :provider_meta])
    |> validate_required([:status])
  end

  defp validate_address_format(changeset) do
    case get_field(changeset, :network) do
      :solana ->
        validate_change(changeset, :address, fn :address, address ->
          # Solana addresses are base58-encoded, 32-44 characters
          if byte_size(address) in 32..44 and valid_base58?(address),
            do: [],
            else: [address: "invalid Solana address format"]
        end)

      _ ->
        changeset
    end
  end

  defp valid_base58?(string) do
    # Base58 alphabet: 1-9, A-Z (excluding I,O), a-z (excluding l)
    String.match?(string, ~r/^[1-9A-HJ-NP-Za-km-z]+$/)
  end
end
