defmodule GameniteWeb.Components.OptionsTable.Row do
  use Surface.Component

  alias Surface.Components.Form.{Field, Label, ErrorTag}

  prop(name, :atom, required: true)
  prop(label, :string, required: true)
  prop(first?, :boolean, default: false)
  prop(last?, :boolean, default: false)
  slot(icon, required: true)
  slot(input, required: true)

  def render(assigns) do
    label_column = get_label_class(assigns)
    input_column = get_input_class(assigns)

    ~F"""
    <Field name={@name}>
      <tr>
        <td class={label_column}>
          <div class="flex space-evenly">
          <div class="flex justify-start items-center px-4">
            <div class="w-12 h-12">
              <#slot name="icon"/>
            </div>
            <div class="px-2 mt-1">
              <Label>{@label}</Label>
            </div>
          </div>
          <div class="px-4 flex justify-start text-center items-center">
            <ErrorTag />
          </div>
          </div>
        </td>
        <td class={input_column}>
          <div class="flex justify-center items-center pr-5">
          <#slot name="input" />
          </div>
        </td>
      </tr>
    </Field>
    """
  end

  defp get_label_class(assigns) do
    base_class = "bg-gray-dark text-white font-bold w-3/4"

    cond do
      assigns.first? ->
        base_class <> " rounded-tl-xl"

      assigns.last? ->
        base_class <> " rounded-bl-xl"

      true ->
        base_class
    end
  end

  defp get_input_class(assigns) do
    base_class = "bg-gray-darkest text-white font-bold w-1/4"

    cond do
      assigns.first? ->
        base_class <> " rounded-tr-xl"

      assigns.last? ->
        base_class <> " rounded-br-xl"

      true ->
        base_class
    end
  end
end
