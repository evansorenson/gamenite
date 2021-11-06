defmodule GameniteWeb.Components.OptionsTable.Row do
  use Surface.Component

  alias Surface.Components.Form.{Field, Label, ErrorTag}

  prop name, :atom, required: true
  prop label, :string, required: true
  prop first?, :boolean, default: false
  prop last?, :boolean, default: false
  slot icon, required: true
  slot input, required: true

  def render(assigns) do
    ~F"""
    <Field name={@name}>
      <tr>
        <td class="bg-gray-dark text-white font-bold w-1/2 rounded-tl-lg">
          <div class="flex justify-start items-center px-4">
            <div class="w-12 h-12">
              <#slot name="icon"/>
            </div>
            <div class="px-2 mt-1">
              <Label>{@label}</Label>
              <ErrorTag />
            </div>
          </div>
        </td>
        <td class="bg-gray-darkest text-white font-bold w-1/2 rounded-tr-lg">
          <#slot name="input" />
        </td>
      </tr>
    </Field>
    """
  end
end
