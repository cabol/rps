defmodule Rps.Cache do
  use Nebulex.Cache, otp_app: :rps

  defmodule Local do
    use Nebulex.Cache, otp_app: :rps
  end
end
