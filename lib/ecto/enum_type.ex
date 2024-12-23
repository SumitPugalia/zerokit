defmodule Zerokit.Ecto.EnumType do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts], unquote: false do
      types = Keyword.fetch!(opts, :type)

      def types(), do: unquote(types)
      def types_str(), do: Enum.map(unquote(types), &to_string/1)

      def cast(atom) when is_atom(atom) do
        if atom in types(), do: atom, else: nil
      end

      def cast(str) when is_bitstring(str) do
        if str in types_str(),
          do: String.to_existing_atom(str),
          else: nil
      end

      def cast(_str), do: nil

      def integer_mapping(), do: Enum.with_index(unquote(types), 1)

      for type <- types do
        def unquote(type)(), do: unquote(type)
        def unquote(:"#{type}_str")(), do: to_string(unquote(type))
        Module.put_attribute(__MODULE__, :export, type)
      end
    end
  end
end
