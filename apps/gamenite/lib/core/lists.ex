defmodule Gamenite.Lists do

  def next_list_element(list, element) do
    curr_idx = find_element_index(list, element)
    next_idx = next_list_index(list, curr_idx)
    Enum.at(list, next_idx)
  end

  def next_list_element_by_id(list, id) do
    curr_idx = find_element_index_by_id(list, id)
    next_idx = next_list_index(list, curr_idx)
    Enum.at(list, next_idx)
  end

  def find_element_by_id(list, id) do
    Enum.at(list, find_element_index_by_id(list, id))
  end

  def find_element_index(list, element) do
    Enum.find_index(list, &(&1 == element))
  end
  def find_element_index_by_id(list, id) do
    Enum.find_index(list, &(&1.id == id))
  end


  defp next_list_index(list, index) when index >= 0 and index < Kernel.length(list), do: rem(index + 1, length(list))
  defp next_list_index(_, _), do: {:error, "Index must be between 0 (inclusive) and length of list "}
end
