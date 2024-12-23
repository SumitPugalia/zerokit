defmodule Zerokit.Ecto.Validator do
  import Ecto.Changeset

  def validate_conditional_required(%Ecto.Changeset{valid?: false} = cs, _, _, _), do: cs

  def validate_conditional_required(cs, field, value, required_field) do
    if get_change(cs, field) == value, do: validate_required(cs, required_field), else: cs
  end

  def validate_status_change(changeset, key, valid_status_change) do
    old_status = Map.get(changeset.data, key)
    new_status = Map.get(changeset.changes, key)

    if new_status do
      old_status = if is_nil(old_status), do: old_status, else: to_string(old_status)

      if to_string(new_status) in valid_status_change[old_status],
        do: changeset,
        else:
          add_error(changeset, key, "Cannot change #{key} from #{old_status} to #{new_status}")
    else
      changeset
    end
  end

  def validate_one_of(changeset, field, other_field) do
    case get_field(changeset, other_field) do
      nil -> validate_required(changeset, field)
      _value -> changeset
    end
  end

  def validate_child(changeset, field, value, required_fields) do
    case get_change(changeset, field) == value do
      true -> validate_required(changeset, required_fields)
      false -> changeset
    end
  end
end
