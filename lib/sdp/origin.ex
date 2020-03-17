defmodule Membrane.Protocol.SDP.Origin do
  @moduledoc """
  This module represents Origin field of SDP that represents
  originator of the session.

  If username is set to `-` the originating host does not support the concept of user IDs.

  Username MUST NOT contain spaces.

  For more details please see [RFC4566 Section 5.2](https://tools.ietf.org/html/rfc4566#section-5.2)
  """

  alias Membrane.Protocol.SDP.ConnectionData

  @enforce_keys [
    :session_id,
    :session_version,
    :address
  ]
  defstruct @enforce_keys ++ [:username]

  @type t :: %__MODULE__{
          username: binary() | nil,
          session_id: binary(),
          session_version: binary(),
          address: ConnectionData.sdp_address()
        }

  @type reason :: :invalid_address | ConnectionData.reason()

  @spec parse(binary()) :: {:ok, t()} | {:error, reason}
  def parse(origin) do
    with [username, sess_id, sess_version, conn_info] <- String.split(origin, " ", parts: 4),
         {:ok, conn_info} <- ConnectionData.parse(conn_info) do
      username = if username == "-", do: nil, else: username

      origin = %__MODULE__{
        username: username,
        session_id: sess_id,
        session_version: sess_version,
        address: conn_info
      }

      {:ok, origin}
    else
      {:error, _} = error -> error
      _ -> {:error, :invalid_origin}
    end
  end

  @spec serialize(t()) :: binary()
  def serialize(origin) do
    with {:ok, serialized_address} <- ConnectionData.serialize_address(origin.address) do
      origin_serialized_fields = [
        serialize_username(origin.username),
        origin.session_id,
        origin.session_version,
        serialized_address
      ]

      "o=" <> Enum.join(origin_serialized_fields, " ")
    end
  end

  defp serialize_username(nil), do: "-"
  defp serialize_username(username), do: username
end
