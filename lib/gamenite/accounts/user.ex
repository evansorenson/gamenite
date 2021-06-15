defmodule Gamenite.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email])
    |> validate_required([:username, :email])
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> validate_length(:username, min: 3, max: 15)
  end

  def registration_changeset(user, params) do
    user
    |> changeset(params)
    |> cast(params, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation])
    |> validate_password()
    |> unique_email()
    |> put_pass_hash()
  end

  defp unique_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9-\.]+\.[a-zA-Z]{2,}$/)
    |> validate_length(:email, max: 255)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_length(:password, min: 8, max: 40)
    |> validate_format(:password, ~r/[0-9]+/, message: "Password missing a number") # has a number
    |> validate_format(:password, ~r/[A-Z]+/, message: "Password missing an upper-case letter") # has an upper case letter
    |> validate_format(:password, ~r/[a-z]+/, message: "Password missing a lower-case letter") # has a lower case letter
    |> validate_format(:password, ~r/[#\!\?&@\$%^&*\(\)]+/, message: "Password missing a symbol") # Has a symbol
    |> validate_confirmation(:password)
  end

  defp put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Pbkdf2.hash_pwd_salt(pass))
      _ -> changeset
    end
  end
end
