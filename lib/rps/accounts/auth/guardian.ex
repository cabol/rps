defmodule Rps.Accounts.Auth.Guardian do
  use Guardian, otp_app: :rps

  alias Rps.Accounts

  def subject_for_token(user, _claims) do
    sub = to_string(user.id)
    {:ok, sub}
  end

  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user(id) do
      nil  -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end
end
