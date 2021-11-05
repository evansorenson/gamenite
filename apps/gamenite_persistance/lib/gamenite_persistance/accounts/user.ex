defmodule GamenitePersistance.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "users" do
    field :username, :string
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :name, :string, virtual: true

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_required([:username])
  end

  def registration_changeset(user, params) do
    user
    |> changeset(params)
    |> cast(params, [:username, :email, :password, :password_confirmation])
    |> unique_constraint(:username)
    |> validate_length(:username, min: 3, max: 15)
    |> validate_required([:username, :email, :password, :password_confirmation])
    |> unique_constraint(:email)
    |> unique_email()
    |> validate_password()
    |> put_pass_hash()
  end

  defp unique_email(changeset) do
    changeset
    |> validate_format(
      :email,
      ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9-\.]+\.[a-zA-Z]{2,}$/
    )
    |> validate_length(:email, max: 255)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_length(:password, min: 8, max: 40)
    # has a number
    |> validate_format(:password, ~r/[0-9]+/, message: "Password missing a number")
    # has an upper case letter
    |> validate_format(:password, ~r/[A-Z]+/, message: "Password missing an upper-case letter")
    # has a lower case letter
    |> validate_format(:password, ~r/[a-z]+/, message: "Password missing a lower-case letter")
    # Has a symbol
    |> validate_format(:password, ~r/[#\!\?&@\$%^&*\(\)]+/, message: "Password missing a symbol")
    |> validate_confirmation(:password)
  end

  defp put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Pbkdf2.hash_pwd_salt(pass))

      _ ->
        changeset
    end
  end
end
