defmodule Zerokit.Ecto.EncryptType do
  @moduledoc false
  # Check this module conforms to Ecto.type behavior.
  @behaviour Ecto.Type
  require Logger

  # :binary is the data type ecto uses internally
  def type, do: :binary

  # cast/1 simply calls to_string on the value and returns a "success" tuple
  def cast(value) do
    {:ok, to_string(value)}
  end

  # dump/1 is called when the field value is about to be written to the database
  def dump(value) do
    encrypt(value, Application.get_env(:zerokit, :encryption_key))
  end

  # load/1 is called when the field is loaded from the database
  def load(value) do
    decrypt(value, Application.get_env(:zerokit, :encryption_key))
  end

  # embed_as/1 dictates how the type behaves when embedded (:self or :dump)
  # preserve the type's higher level representation
  def embed_as(_), do: :self

  # equal?/2 is called to determine if two field values are semantically equal
  def equal?(value1, value2), do: value1 == value2

  defp encrypt(value, key) do
    ciphertext = Plug.Crypto.encrypt(key, "encrypt", value, max_age: :infinity)
    {:ok, ciphertext}
  rescue
    err ->
      Logger.error("Error for Encryption #{inspect(err)}")
      {:error, "Encryption failed"}
  end

  # Function to decrypt the Base64 encoded value using AES-256-CBC
  defp decrypt(encoded_value, key) do
    Plug.Crypto.decrypt(key, "encrypt", encoded_value, max_age: :infinity)
  rescue
    err ->
      Logger.error("Error for Decryption #{inspect(err)}")
      {:error, "Decryption failed"}
  end
end
